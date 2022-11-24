// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/powerpool-agent-v2/lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/powerpool-agent-v2/lib/openzeppelin-contracts/contracts/security/Pausable.sol";
import "../lib/powerpool-agent-v2/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { IPPAgentV2Viewer } from "../lib/powerpool-agent-v2/contracts/PPAgentV2.sol";

interface IUniswapV2Router01Local {
  function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

  function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

  function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPPAgentV2 {
  function depositJobCredits(bytes32 jobKey_) external payable;
}

// * Does not support topping up owner credits, only job credits supported
contract JobKeeper is Ownable, Pausable {
  error HasNoJobsWithCreditsBelowMin();
  event Execute(uint256 jobsTopuped, uint256 jobsTotal, uint256 cvpAmountIn, uint256 ethAmountOut);

  event SetJobs(uint256 len, bytes32[] jobs);
  event SetCreditLimits(
    uint256 minCredits_,
    uint256 topupRequiredCredits_,
    uint256 targetCredits_
  );

  bytes32[] public jobs;

  // minCredits - if any of jobs has credits balance lower than min credits, the topup job can be executed
  uint256 public minCredits;
  // topupRequiredCredits - if a job has balance lower than this value, it will be topuped during the execution
  uint256 public topupRequiredCredits;
  // target credits - topup a job up to this balance
  uint256 public targetCredits;

  address public immutable PPAGENT_V2;
  address public immutable TREASURY;
  address public immutable UNISWAP_V2_ROUTER;
  address public immutable CVP;
  address public immutable EXECUTOR;
  address[] public SWAP_PATH;

  receive() external payable {
  }

  constructor(
    address ppAgentV2_,
    address treasury_,
    address uniswapV2Router_,
    address executor_,
    address cvp_,
    uint256 targetCredits_,
    uint256 topupRequiredCredits_,
    uint256 minCredits_,
    bytes32[] memory jobs_,
    address[] memory swapPath_
  ) {
    PPAGENT_V2 = ppAgentV2_;
    TREASURY = treasury_;
    UNISWAP_V2_ROUTER = uniswapV2Router_;
    EXECUTOR = executor_;
    CVP = cvp_;
    _setCreditLimits(minCredits_, topupRequiredCredits_, targetCredits_);
    _setJobs(jobs_);
    SWAP_PATH = swapPath_;
  }

  function setJobs(bytes32[] calldata jobs_) external onlyOwner {
    _setJobs(jobs_);
  }

  function _setJobs(bytes32[] memory jobs_) internal {
    jobs = jobs_;
    emit SetJobs(jobs_.length, jobs_);
  }

  function setCreditLimits(
    uint256 minCredits_,
    uint256 topupRequiredCredits_,
    uint256 targetCredits_
  ) external onlyOwner {
    _setCreditLimits(minCredits_, topupRequiredCredits_, targetCredits_);
  }

  function _setCreditLimits(
    uint256 minCredits_,
    uint256 topupRequiredCredits_,
    uint256 targetCredits_
  ) internal {
    require(topupRequiredCredits_ >= minCredits_, "topupRequiredCredits_ >= minCredits_");
    require(targetCredits_ >= topupRequiredCredits_, "targetCredits_ >= topupRequiredCredits_");

    emit SetCreditLimits(minCredits_, topupRequiredCredits_, targetCredits_);

    minCredits = minCredits_;
    topupRequiredCredits = topupRequiredCredits_;
    targetCredits = targetCredits_;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function doCall(
    address destination,
    bytes calldata payload,
    uint256 eths,
    bool doRevert
  ) external onlyOwner {
    (bool ok, bytes memory data) = destination.call{ value: eths }(payload);

    if (!ok && doRevert) {
      assembly {
        let size := returndatasize()
        revert(add(data, 32), size)
      }
    }
  }

  function resolver() external view returns (bool ok, bytes memory data) {
    if (paused()) {
      return (false, new bytes(0));
    }

    bytes32[] memory _jobs = jobs;
    data = new bytes(0);
    ok = false;
    uint256 len = _jobs.length;
    uint256 _minCredits = minCredits;

    for (uint256 i = 0; i < len; i++) {
      uint256 jobRaw = IPPAgentV2Viewer(PPAGENT_V2).getJobRaw(_jobs[i]);
      uint256 jobCredits = (jobRaw << 128) >> 168;

      if (jobCredits < _minCredits) {
        return (true, abi.encodeWithSelector(JobKeeper.execute.selector));
      }
    }
  }

  function execute() external whenNotPaused {
    require(msg.sender == EXECUTOR, "!executor");
    bytes32[] memory _jobs = jobs;
    uint256 len = _jobs.length;
    uint256 _minCredits = minCredits;
    uint256 _topupRequiredCredits = topupRequiredCredits;
    uint256 _targetCredits = targetCredits;
    bool hasOneLowerThanMin = false;
    uint256 ethToTopUpTotal = 0;
    uint256[] memory topUps = new uint256[](len);
    uint256 jobsTopuped = 0;
    (,,,uint256 feePpm,) = IPPAgentV2Viewer(PPAGENT_V2).getConfig();

    // Collect required topup data
    for (uint256 i = 0; i < len; i++) {
      uint256 jobRaw = IPPAgentV2Viewer(PPAGENT_V2).getJobRaw(_jobs[i]);
      uint256 jobCredits = (jobRaw << 128) >> 168;

      if (jobCredits < _topupRequiredCredits) {
        uint256 diff = _targetCredits - jobCredits;
        if (feePpm > 0) {
          diff = diff / (1e6 - feePpm - 1) * 1e6;
        }
        topUps[i] = diff;
        ethToTopUpTotal += diff;
        jobsTopuped += 1;
      }
      if (jobCredits < _minCredits) {
        hasOneLowerThanMin = true;
      }
    }

    if (!hasOneLowerThanMin) {
      revert HasNoJobsWithCreditsBelowMin();
    }

    // Estimate required CVP
    uint256[] memory cvpAmountIn = IUniswapV2Router01Local(UNISWAP_V2_ROUTER)
      .getAmountsIn(ethToTopUpTotal, SWAP_PATH);

    IERC20(CVP).transferFrom(TREASURY, address(this), cvpAmountIn[0]);
    IERC20(CVP).approve(UNISWAP_V2_ROUTER, cvpAmountIn[0]);
    IUniswapV2Router01Local(UNISWAP_V2_ROUTER)
      .swapTokensForExactETH(ethToTopUpTotal, cvpAmountIn[0], SWAP_PATH, address(this), block.timestamp + 1);

    // Topping up the jobs
    for (uint256 i = 0; i < len; i++) {
      uint256 amount = topUps[i];
      if (amount > 0) {
        IPPAgentV2(PPAGENT_V2).depositJobCredits{value: amount}(_jobs[i]);
      }
    }

    emit Execute(
      jobsTopuped,
      len,
      cvpAmountIn[0],
      ethToTopUpTotal
    );
  }

  function getJobs() external view returns (bytes32[] memory) {
    return jobs;
  }

  function getJobsLength() external view returns (uint256) {
    return jobs.length;
  }
}