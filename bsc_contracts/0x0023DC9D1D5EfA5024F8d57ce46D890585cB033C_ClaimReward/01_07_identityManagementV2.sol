//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ClaimReward is Pausable, Ownable {
    using ECDSA for bytes32;
    IERC20 public token;

    struct OpenRequest {
        address tokenAddress;
        uint256 amount;
        uint256 lastClaimtime;
        string nonce;
    }
    struct ClaimInfo {
        address recipient;
        address tokenAddress;
        uint256 amount;
        string nonce;
        uint256 blocktime;
    }
    struct LastClaim {
        uint256 blocktime;
        bool isVal;
    }
    mapping(string => bool) private _nonce;
    address private _signer;
    mapping(string => LastClaim) public lastClaimedTime;
    mapping(string => ClaimInfo[]) public ClaimHistory;

    event ClaimedReward(address recipient, address tokenAddress, uint256 amount, string stakingId, uint256 blocktime);

    constructor() {}

    function claim(
        string memory stakingId,
        bytes calldata requestData,
        bytes calldata signature
    ) external {
        _validateRequest(requestData, signature);
        OpenRequest memory request = abi.decode(requestData, (OpenRequest));
        address tokenAddress = request.tokenAddress;
        uint256 amount = request.amount;
        uint256 lastClaimtime = request.lastClaimtime;

        if (lastClaimedTime[stakingId].isVal) {
            require(lastClaimtime == lastClaimedTime[stakingId].blocktime, "This claim is not match with last cliamed time.");
        }

        // send amount of token to recipient
        token = IERC20(tokenAddress);
        token.transfer(msg.sender, amount);
        
        uint256 blocktime = block.timestamp;
        // save last nonce of staking
        lastClaimedTime[stakingId] = LastClaim(blocktime, true);
        // save claim history
        ClaimHistory[stakingId].push(ClaimInfo(msg.sender, tokenAddress, amount, request.nonce, blocktime));

        emit ClaimedReward(msg.sender, tokenAddress, amount, stakingId, blocktime);
    }

    function _validateRequest(
        bytes calldata requestData,
        bytes calldata signature
    ) internal {
        OpenRequest memory request = abi.decode(requestData, (OpenRequest));
        string memory nonce = request.nonce;

        require(!_nonce[nonce], "ClaimReward: Already used!");

        bytes32 requestHash = keccak256(
            abi.encodePacked(address(this), msg.sender, requestData)
        );

        address signerFromHash = requestHash.toEthSignedMessageHash().recover(
            signature
        );
        require(signerFromHash == _signer, "ClaimReward: Invalid Signer");
        _nonce[nonce] = true;
    }

    function setSignerAddress(address newSigner) external onlyOwner {
        _signer = newSigner;
    }

    function withdraw(address recipient, address tokenAddress) external onlyOwner {
        token = IERC20(tokenAddress);
        token.transfer(recipient, token.balanceOf(address(this)));
    }
}