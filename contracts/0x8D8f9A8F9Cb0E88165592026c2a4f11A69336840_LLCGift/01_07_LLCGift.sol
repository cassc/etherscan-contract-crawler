//  ________  ___       ___  ___  ________  ________  ________  ________  _______
// |\   ____\|\  \     |\  \|\  \|\   __  \|\   __  \|\   __  \|\   __  \|\  ___ \
// \ \  \___|\ \  \    \ \  \\\  \ \  \|\ /\ \  \|\  \ \  \|\  \ \  \|\  \ \   __/|
//  \ \  \    \ \  \    \ \  \\\  \ \   __  \ \   _  _\ \   __  \ \   _  _\ \  \_|/__
//   \ \  \____\ \  \____\ \  \\\  \ \  \|\  \ \  \\  \\ \  \ \  \ \  \\  \\ \  \_|\ \
//    \ \_______\ \_______\ \_______\ \_______\ \__\\ _\\ \__\ \__\ \__\\ _\\ \_______\
//     \|_______|\|_______|\|_______|\|_______|\|__|\|__|\|__|\|__|\|__|\|__|\|_______|
//

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/ILLC.sol";
import "./interfaces/ILLCTier.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract LLCGift is Ownable, Pausable, ReentrancyGuard {
    /// @dev LLC NFT contract
    address public LLC;

    /// @dev ETH-AGOV Staking contract
    address public ETH_AGOV_STAKING;

    /// @dev LLC Claimers
    mapping(address => uint256) public claimers;

    /// @dev LLC Claim Status
    mapping(address => uint256) public claimStatuses;

    constructor(address _llc, address _staking) {
        LLC = _llc;
        ETH_AGOV_STAKING = _staking;
        _pause();
    }

    /// @dev Set LLC contract address
    function setLLC(address _llc) external onlyOwner {
        LLC = _llc;
        emit SetLLC(_llc);
    }

    /// @dev Set ETH-AGOV Staking contract address
    function setStaking(address _staking) external onlyOwner {
        ETH_AGOV_STAKING = _staking;
        emit SetStaking(_staking);
    }

    /// @dev Mint LLCs
    function mint(uint256 _amount) external onlyOwner {
        getLLC().mint(address(this), _amount);
    }

    /// @dev Pause
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Unpause
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Add claimer to the list of claimers
    function addClaimer(address _claimer, uint256 _amount)
        external
        onlyStakingOrOwner
    {
        claimers[_claimer] = _amount;
        emit Claimer(_claimer, _amount);
    }

    /// @dev Claim LLC
    function claim(address _who, uint256[] calldata _tokenIds)
        external
        nonReentrant
        whenNotPaused
    {
        uint256 amount = _tokenIds.length;
        require(amount > 0, "Empty TokenIds");

        uint256 status = claimStatuses[_msgSender()] + amount;
        if (owner() != _msgSender()) {
            require(status <= claimers[_msgSender()], "Overflow");
        }

        uint256 tokenId;
        ILLC llc = getLLC();
        for (uint256 i = 0; i < amount; i++) {
            tokenId = _tokenIds[i];
            llc.transferFrom(address(this), _who, tokenId);
            emit Claimed(_who, tokenId);
        }

        claimStatuses[_msgSender()] = status;
    }

    /// @dev Withdraw LLCs
    function withdrawTokens(address _who, uint256[] calldata _tokenIds)
        external
        onlyOwner
    {
        uint256 amount = _tokenIds.length;
        require(amount > 0, "Empty TokenIds");
        ILLC llc = getLLC();
        uint256 tokenId;
        for (uint256 i = 0; i < amount; i++) {
            tokenId = _tokenIds[i];
            llc.transferFrom(address(this), _who, tokenId);
            emit Claimed(_who, tokenId);
        }
    }

    /// @dev Get LLC contract
    function getLLC() public view returns (ILLC) {
        return ILLC(LLC);
    }

    /// @dev Get Staking contract
    function getStaking() public view returns (address) {
        return ETH_AGOV_STAKING;
    }

    modifier onlyStakingOrOwner() {
        require(
            _msgSender() == getStaking() || _msgSender() == owner(),
            "Only staking contract can call this function"
        );
        _;
    }

    event SetLLC(address llc);
    event SetStaking(address staking);
    event Claimer(address claimer, uint256 amount);
    event Claimed(address claimer, uint256 tokenId);
}