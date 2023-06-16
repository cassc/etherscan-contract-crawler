// SPDX-License-Identifier: CODESEKAI
pragma solidity =0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

interface INFTCORE {
    enum MintType {
        Whitelist,
        Waitlist,
        Mint
    }

    function mint(
        address _userAddr,
        string calldata metadata,
        MintType _mintType
    ) external;
}

contract CSKGen is EIP712, AccessControl, ReentrancyGuard {
    INFTCORE public nftCore;
    address payable public adminWallet;
    address public signWallet;

    uint256 public constant MAXIMUM_MINT_PRICE = 0.08 ether;
    uint256 public MINT_PRICE = 0.08 ether;
    uint256 public WHITELIST_PRICE = 0.069 ether;
    uint256 public WAITLIST_PRICE = 0.069 ether;

    struct MintAmount {
        uint8 WlRound;
        uint8 PbRound;
    }

    struct MintInfo {
        address minter;
        uint256 timestamp;
        uint256 mintType;
        uint256 metadata;
        uint256 nonce;
        bytes signature;
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

    event SetNftCore(
        address indexed prevNftCore,
        address indexed newNftCore
    );
    event SetAdminWallet(
        address indexed prevAdminWallet,
        address indexed adminWallet
    );
    event SetSignWallet(
        address indexed prevSignWallet,
        address indexed signWallet
    );
    event SetPrice(
        uint256 indexed mintType,
        uint256 indexed prevPrice,
        uint256 indexed newPrice
    );
    event SetWhitelist(
        uint256 indexed mintType,
        address[] indexed _userAddresses
    );
    event GenToken(
        address indexed minter,
        uint256 indexed mintType,
        uint256 indexed metadata
    );

    event SetTimelock(
        address indexed prevTimelockAddress,
        address indexed newTimeLockAddress
    );

    /// @dev why you are reading this line ?
    string public constant SIGNING_DOMAIN = "CODESEKAI";
    string public constant SIGNATURE_VERSION = "1";
    bytes32 public constant TIMELOCK_DEV_ROLE = keccak256("TIMELOCK_DEV_ROLE");
    address public timelockAddress;

    constructor(
        address _nftCore,
        address payable _adminWallet,
        address _signWallet,
        address _timelockAddress
    ) EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        require(_nftCore != address(0), "Invalid _nftCore address");
        require(_adminWallet != address(0), "Invalid _adminWallet address");
        require(_signWallet != address(0), "Invalid _signWallet address");
        require(_timelockAddress != address(0), "Invalid address");
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(TIMELOCK_DEV_ROLE, _timelockAddress);
        nftCore = INFTCORE(_nftCore);
        adminWallet = _adminWallet;
        signWallet = _signWallet;
        timelockAddress = _timelockAddress;
    }

    mapping(MintType => mapping(address => bool)) public wlLists;
    mapping(address => MintAmount) public mintTotalCount;
    mapping(address => uint256) public genTokenNonces;

    function getTotalMinted() public view returns (uint8, uint8) {
        return (
            mintTotalCount[msg.sender].WlRound,
            mintTotalCount[msg.sender].PbRound
        );
    }

    function setNftCore(
        address _newNftCore
    ) public onlyRole(TIMELOCK_DEV_ROLE) {
        require(_newNftCore != address(0), "Invalid _newNftCore address");
        address prevNftCore = address(nftCore);
        nftCore = INFTCORE(_newNftCore);

        emit SetNftCore(prevNftCore, _newNftCore);
    }

    function setSignWallet(
        address _newSignWallet
    ) public onlyRole(TIMELOCK_DEV_ROLE) {
        require(_newSignWallet != address(0), "Invalid _newSignWallet address");
        address prevSignWallet = signWallet;
        signWallet = _newSignWallet;

        emit SetSignWallet(prevSignWallet, _newSignWallet);
    }

    function setPrice(
        MintType _mintType,
        uint256 newPrice
    ) public onlyRole(TIMELOCK_DEV_ROLE) {
        require(
            newPrice <= MAXIMUM_MINT_PRICE,
            "New mint price exceeds the maximum allowed value"
        );
        uint256 prevPrice;

        if (_mintType == MintType.Mint) {
            require(
                newPrice > WAITLIST_PRICE,
                "MINT_PRICE must be greater than WAITLIST_PRICE"
            );
            prevPrice = MINT_PRICE;
            MINT_PRICE = newPrice;
        } else if (_mintType == MintType.Whitelist) {
            require(
                newPrice <= WAITLIST_PRICE,
                "WHITELIST_PRICE must be less than or equal to WAITLIST_PRICE"
            );
            prevPrice = WHITELIST_PRICE;
            WHITELIST_PRICE = newPrice;
        } else if (_mintType == MintType.Waitlist) {
            require(
                newPrice >= WHITELIST_PRICE && newPrice < MINT_PRICE,
                "WAITLIST_PRICE must be between WHITELIST_PRICE and MINT_PRICE"
            );
            prevPrice = WAITLIST_PRICE;
            WAITLIST_PRICE = newPrice;
        }

        emit SetPrice(uint256(_mintType), prevPrice, newPrice);
    }

    function checkWl(
        MintType wlTier,
        address _address
    ) public view returns (bool) {
        return wlLists[wlTier][_address];
    }

    //@dev call this to set wlLists before start
    function setWhitelists(
        MintType wlType,
        address[] memory _userAddresses,
        Whitelist _doType
    ) public onlyRole(TIMELOCK_DEV_ROLE) {
        if (_doType == Whitelist.Add) {
            for (uint32 i = 0; i < _userAddresses.length; i++) {
                if (!wlLists[wlType][_userAddresses[i]]) {
                    wlLists[wlType][_userAddresses[i]] = true;
                }
            }
        } else if (_doType == Whitelist.Remove) {
            for (uint32 i = 0; i < _userAddresses.length; i++) {
                if (wlLists[wlType][_userAddresses[i]]) {
                    wlLists[wlType][_userAddresses[i]] = false;
                }
            }
        }
        emit SetWhitelist(uint256(wlType), _userAddresses);
    }

    function loopGenToken(MintType _mintType, uint256 metadata) internal {
        string memory results = Strings.toString(metadata);
        if (_mintType == MintType.Mint) {
            mintTotalCount[msg.sender].PbRound += 1;
            nftCore.mint(msg.sender, results, INFTCORE.MintType.Mint);
        } else if (_mintType == MintType.Whitelist) {
            mintTotalCount[msg.sender].WlRound += 1;
            nftCore.mint(msg.sender, results, INFTCORE.MintType.Whitelist);
        } else if (_mintType == MintType.Waitlist) {
            mintTotalCount[msg.sender].WlRound += 1;
            nftCore.mint(msg.sender, results, INFTCORE.MintType.Waitlist);
        }
    }

    function _hash(MintInfo memory info) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "MintInfo(address minter,uint256 timestamp,uint256 mintType,uint256 metadata,uint256 nonce)"
                        ),
                        info.minter,
                        info.timestamp,
                        info.mintType,
                        info.metadata,
                        info.nonce
                    )
                )
            );
    }

    function _verify(MintInfo memory info) internal view returns (address) {
        bytes32 digest = _hash(info);
        return ECDSA.recover(digest, info.signature);
    }

    function getTime() external view returns (uint256) {
        return block.timestamp;
    }

    function genToken(MintInfo calldata info) external payable nonReentrant {
        uint256 ethAmount;
        MintType mintType;
        require(block.timestamp <= info.timestamp + 30 seconds, "Times out");
        require(info.minter == msg.sender, "not minter");

        address signer = _verify(info);
        require(signer == signWallet, "not signed");
        require(info.nonce >= genTokenNonces[msg.sender]++, "Invalid nonce");

        if (info.mintType == 0) {
            require(mintTotalCount[msg.sender].WlRound == 0, "Wl Minted");
            
            ethAmount = WHITELIST_PRICE;
            mintType = MintType.Whitelist;
        } else if (info.mintType == 1) {
            require(mintTotalCount[msg.sender].WlRound == 0, "Wl Minted");
            
            ethAmount = WAITLIST_PRICE;
            mintType = MintType.Waitlist;
        } else if (info.mintType == 2) {
            require(mintTotalCount[msg.sender].PbRound == 0, "Pb Minted");
            ethAmount = MINT_PRICE;
            mintType = MintType.Mint;
        } else {
            revert("Incorrect Minting Type: Out Of Range");
        }

        require(msg.value == ethAmount, "Invalid Amount");
        (bool sent, ) = adminWallet.call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        loopGenToken(mintType, info.metadata);
        emit GenToken(info.minter, info.mintType, info.metadata);
    }

    function grantRole(
        bytes32 role,
        address account
    ) public virtual override(AccessControl) onlyRole(TIMELOCK_DEV_ROLE) {
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
    ) public virtual override(AccessControl) onlyRole(TIMELOCK_DEV_ROLE) {
        _revokeRole(role, account);
    }

    function setAdminWallet(
        address payable _adminWallet
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_adminWallet != address(0), "Invalid address");
        address prevAdminWallet = adminWallet;
        adminWallet = _adminWallet;
        emit SetAdminWallet(prevAdminWallet, adminWallet);
    }

    function setTimelock(
        address newTimelockAddress
    ) external onlyRole(TIMELOCK_DEV_ROLE) {
        require(
            newTimelockAddress != address(0),
            "Invalid newTimelockAddress address"
        );
        address prevTimelockAddress = timelockAddress;
        timelockAddress = newTimelockAddress;
        _revokeRole(TIMELOCK_DEV_ROLE, prevTimelockAddress);
        _grantRole(TIMELOCK_DEV_ROLE, newTimelockAddress);
        emit SetTimelock(prevTimelockAddress, newTimelockAddress);
    }
}