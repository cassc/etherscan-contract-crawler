// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPolygonPOSStakingContract {
    function withdrawRewards(uint256 validatorId) external;
    function updateCommissionRate(uint256 validatorId, uint256 newCommissionRate) external;
    function updateSigner(uint256 validatorId, bytes memory signerPubkey) external;
}

contract PolygonValidatorContract is AccessControlEnumerable, IERC721Receiver {
    /************************* Constants *************************/

    uint256 public constant VALIDATOR_NFT_ID = 106;
    address public constant POLYGON_VALIDATOR_NFT_CONTRACT = address(0x47Cbe25BbDB40a774cC37E1dA92d10C2C7Ec897F);
    address public constant POLYGON_POS_STAKING_CONTRACT = address(0x5e3Ef299fDDf15eAa0432E6e66473ace8c13D908);
    address public constant MATIC_TOKEN = address(0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0);

    bytes32 public constant ROLE_A = keccak256(abi.encode("PARTY_A"));
    bytes32 public constant ROLE_B = keccak256(abi.encode("PARTY_B"));
    
    /************************* Init *************************/

    constructor(address _partyB) {
        _setupRole(ROLE_B, _partyB);
        _setRoleAdmin(ROLE_A, ROLE_A);
        _setRoleAdmin(ROLE_B, ROLE_B);
    }

    /************************* Overrides *************************/

    function _revokeRole(bytes32 role, address account) internal override {
        super._revokeRole(role, account);

        // protect against accidentally removing all accounts with the role
        if( role == ROLE_A || role == ROLE_B ) {
            require(getRoleMemberCount(role) != 0, "noone else with revoked role");
        }
    }

    /************************* Owner methods *************************/

    function withdrawValidatorNFT(address _to) public onlyRole(ROLE_A) {
        // protect against withdrawing NFT to contracts which might not have a way to withdraw NFT
        require(_to.code.length == 0, "Receiver is a contract");
        IERC721(POLYGON_VALIDATOR_NFT_CONTRACT).transferFrom(address(this), _to, VALIDATOR_NFT_ID);
    }

    /************************* NFT Receiver Hook *************************/

    function onERC721Received(
        address /*operator*/,
        address /*from*/,
        uint256 tokenId,
        bytes calldata /*data*/
    ) external returns (bytes4) {
        // only accept specified validator NFT
        require(msg.sender == POLYGON_VALIDATOR_NFT_CONTRACT, "Unknown NFT");
        require(tokenId == VALIDATOR_NFT_ID, "Unexpected NFT Id");
        // origin of tx where NFT is received gets ROLE_A
        _grantRole(ROLE_A, tx.origin);
        return 0x150b7a02; // IERC721Receiver.onERC721Received.selector
    }

    /************************* Lessee methods *************************/

    function withdrawRewards() public onlyRole(ROLE_B) {
        IPolygonPOSStakingContract(POLYGON_POS_STAKING_CONTRACT).withdrawRewards(VALIDATOR_NFT_ID);
        uint256 balance = IERC20(MATIC_TOKEN).balanceOf(address(this));
        IERC20(MATIC_TOKEN).transfer(msg.sender, balance);
    }

    function updateCommissionRate(uint256 newCommissionRate) public onlyRole(ROLE_B) {
        IPolygonPOSStakingContract(POLYGON_POS_STAKING_CONTRACT).updateCommissionRate(VALIDATOR_NFT_ID, newCommissionRate);
    }

    function updateSigner(bytes memory signerPubkey) public onlyRole(ROLE_B) {
        IPolygonPOSStakingContract(POLYGON_POS_STAKING_CONTRACT).updateSigner(VALIDATOR_NFT_ID, signerPubkey);
    }
}