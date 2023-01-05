// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./interfaces/solidly/IVotingEscrow.sol";
import "./interfaces/solidly/IBribe.sol";
import "./interfaces/solidly/IBaseV1Voter.sol";

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract NFTHolder is
    Initializable,
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");
    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // solidly contracts
    IVotingEscrow public votingEscrow;
    IBaseV1Voter public solidlyVoter;

    // monlith contracts
    address public moSolid;

    uint256 public tokenID;

    mapping(address => bool) public isRewarder;

    function initialize(
        IERC20Upgradeable _solid,
        IVotingEscrow _votingEscrow,
        IBaseV1Voter _solidlyVoter,
        address admin,
        address pauser,
        address setter,
        address operator
    ) public initializer {
        __Pausable_init();
        __AccessControlEnumerable_init();

        votingEscrow = _votingEscrow;
        solidlyVoter = _solidlyVoter;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(UNPAUSER_ROLE, admin);
        _grantRole(PAUSER_ROLE, pauser);
        _grantRole(SETTER_ROLE, setter);
        _grantRole(OPERATOR_ROLE, operator);
    }

    function setAddresses(address _moSolid) external onlyRole(SETTER_ROLE) {
        moSolid = _moSolid;

        // for merge
        votingEscrow.setApprovalForAll(_moSolid, true);
    }

    function setIsRewarder(address[] memory rewarders, bool status)
        external
        onlyRole(SETTER_ROLE)
    {
        for (uint8 i; i < rewarders.length; i++) {
            isRewarder[rewarders[i]] = status;
        }
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(UNPAUSER_ROLE) {
        _unpause();
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenID,
        bytes calldata
    ) external returns (bytes4) {
        // VeDepositor transfers the NFT to this contract so this callback is required
        require(_operator == moSolid);

        // make sure only voting escrow can call this method
        require(msg.sender == address(votingEscrow));

        if (tokenID == 0) {
            tokenID = _tokenID;
        }

        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function vote(address[] memory pools, int256[] memory weights)
        external
        onlyRole(OPERATOR_ROLE)
    {
        solidlyVoter.vote(tokenID, pools, weights);
    }

    function getReward(address rewarder, address[] memory tokens)
        external
        onlyRole(OPERATOR_ROLE)
    {
        require(isRewarder[rewarder], "NOT REWARDER");
        IBribe(rewarder).getReward(tokenID, tokens);
    }

    function withdrawERC20(address token, address to)
        external
        onlyRole(OPERATOR_ROLE)
    {
        IERC20Upgradeable(token).safeTransfer(
            to,
            IERC20Upgradeable(token).balanceOf(address(this))
        );
    }

    function withdrawNFT(address to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        votingEscrow.safeTransferFrom(address(this), to, tokenID);
    }

    function approveNFT(address to, bool status) external onlyRole(DEFAULT_ADMIN_ROLE) {
        votingEscrow.setApprovalForAll(to, status);
    }
}