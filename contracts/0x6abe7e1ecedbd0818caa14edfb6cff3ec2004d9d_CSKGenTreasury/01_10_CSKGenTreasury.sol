// SPDX-License-Identifier: CODESEKAI
pragma solidity =0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface INFTCORE {
    enum MintType {
        Whitelist,
        Waitlist,
        Mint
    }

    function totalSupply() external view returns (uint256);

    function mint(
        address _userAddr,
        string calldata metadata,
        MintType _mintType
    ) external;
}

contract CSKGenTreasury is AccessControl, ReentrancyGuard {
    INFTCORE public nftCore;
    address payable public adminWallet;
    address public signWallet;

    struct MintAmount {
        uint8 WlRound;
        uint8 PbRound;
    }

    enum MintType {
        Whitelist,
        Waitlist,
        Mint
    }

    enum Whitelist {
        Add,
        Remove
    }

    event GenTreasury(uint256 indexed metadata, uint256 tokendId);
    event BatchGenTreasury(uint256[] indexed metadata);

    /// @dev why you are reading this line ?
    string private constant SIGNING_DOMAIN = "CODESEKAI";
    string private constant SIGNATURE_VERSION = "1";
    address public timelockAddress;
    uint256 public constant MAXIMUM_MINT_AMOUNT = 255;

    constructor(address _nftCore) {
        require(_nftCore != address(0), "Invalid _nftCore address");
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        nftCore = INFTCORE(_nftCore);
    }

    mapping(address => MintAmount) public mintTotalCount;

    function getTime() external view returns (uint256) {
        return block.timestamp;
    }

    function getAmountLeft() external view returns (uint256) {
        return MAXIMUM_MINT_AMOUNT - nftCore.totalSupply();
    }

    function numDigits(uint256 number) internal pure returns (uint256 digits) {
        while (number != 0) {
            number /= 10;
            digits++;
        }
        return digits;
    }

    function genToken(
        uint256 _fixedMetadata
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            nftCore.totalSupply() <= MAXIMUM_MINT_AMOUNT,
            "Over Maximum Amount"
        );
        require(numDigits(_fixedMetadata) == 41, "not metadata");

        string memory results = Strings.toString(_fixedMetadata);
        nftCore.mint(msg.sender, results, INFTCORE.MintType.Whitelist);

        emit GenTreasury(_fixedMetadata, nftCore.totalSupply());
    }

    function batchGenToken(
        uint256[] calldata _fixedMetadata
    ) external onlyRole(DEFAULT_ADMIN_ROLE)
     {
        require(
            nftCore.totalSupply() + _fixedMetadata.length <=
                MAXIMUM_MINT_AMOUNT,
            "Over Maximum Amount"
        );
        for (uint i = 0; i < _fixedMetadata.length; i++) {
            require(numDigits(_fixedMetadata[i]) == 41, "not metadata");

            string memory results = Strings.toString(_fixedMetadata[i]);
            nftCore.mint(msg.sender, results, INFTCORE.MintType.Whitelist);
        }
        emit BatchGenTreasury(_fixedMetadata);
    }

    function grantRole(
        bytes32 role,
        address account
    ) public virtual override(AccessControl) onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
    }

    function renounceRole(
        bytes32 role,
        address account
    ) public virtual override(AccessControl) {
        require(
            !(hasRole(DEFAULT_ADMIN_ROLE, account)),
            "AccessControl: cannot renounce the DEFAULT_ADMIN_ROLE account"
        );
        super.renounceRole(role, account);
    }

    function revokeRole(
        bytes32 role,
        address account
    ) public virtual override(AccessControl) onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(role, account);
    }
}