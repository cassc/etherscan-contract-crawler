// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Create2Upgradeable.sol";
import '@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./interfaces/IFractonXFactory.sol";
import "./interfaces/IOwner.sol";
import "./interfaces/IFractonXERC20.sol";
import "./interfaces/IFractonXERC721.sol";
import "./FractonXERC721.sol";
import "./FractonXERC20.sol";

contract FractonXFactory is IFractonXFactory, Initializable, OwnableUpgradeable, ERC721HolderUpgradeable, AccessControlUpgradeable {

    uint256 constant TEN_THOUSAND = 10000;
    bytes4 private constant ERC20_TRANSFER_SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    bytes32 constant public SWAP_ROLE = keccak256("SWAP_ROLE");

    address public override fractionxSwapVault;
    address public override fractionxTransVault;

    uint256 public override swapFeeRate;  // default = 300/10000 = 3/100; swapFee = swapFeeRate / 10000 * swapAmount
    mapping(address => ERC20Info) erc20Addr2info;
    mapping(address => ERC721Info) erc721Addr2info;
    mapping(address => mapping(uint256 => bool)) erc721Addr2tokenId2include;


    uint256 private unlocked;
    uint256 public override closeSwap721To20;   // 1 represent true, 2 represent false
    modifier lock() {
        require(unlocked == 1, 'SWAP: LOCKED');
        unlocked = 2;
        _;
        unlocked = 1;
    }

    modifier onlySwapRole(address erc721Addr) {
        if (!(hasRole(keccak256(abi.encode(erc721Addr)), msg.sender) || hasRole(SWAP_ROLE, msg.sender) ||
            closeSwap721To20 == 2)) {
            revert("INVALID ROLE");
        }
        _;
    }

    function initialize(address swapVault_, address transVault_, uint256 swapFeeRate_) public initializer {
        __FractonXFactory_init();

        unlocked = 1;
        closeSwap721To20 = 1;

        fractionxSwapVault = swapVault_;
        fractionxTransVault = transVault_;
        swapFeeRate = swapFeeRate_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        emit EventSetFractonXVault(transVault_, swapVault_);
    }

    function __FractonXFactory_init() internal onlyInitializing {
        __Ownable_init();
        __ERC721Holder_init();
        __AccessControl_init();
    }

    function createERC20(address erc721Addr, uint256 swapRatio, string memory name, string memory symbol,
        uint256 erc20TransferFee) external onlyOwner returns(address erc20Addr) {

        require(erc721Addr2info[erc721Addr].erc20Addr == address(0), "ALREADY CREATED");
        bytes32 salt = keccak256(abi.encode(erc721Addr));
        erc20Addr = Create2Upgradeable.deploy(0, salt, _getERC20Bytecode(name, symbol, erc20TransferFee));
        erc20Addr2info[erc20Addr].erc721Addr = erc721Addr;
        erc20Addr2info[erc20Addr].swapRatio = swapRatio;

        erc721Addr2info[erc721Addr].erc20Addr = erc20Addr;

        _setRoleAdmin(salt, DEFAULT_ADMIN_ROLE);

        emit EventUpdateRelation(erc721Addr, erc20Addr, swapRatio, false);
    }

    function createERC721(address erc20Addr, uint256 swapRatio, string memory name,
        string memory symbol, string memory tokenUri) external onlyOwner returns(address erc721Addr) {

        require(erc20Addr2info[erc20Addr].erc721Addr == address(0), "ALREADY CREATED");
        bytes32 salt = keccak256(abi.encode(erc20Addr));
        erc721Addr = Create2Upgradeable.deploy(0, salt, _getERC721Bytecode(name, symbol, tokenUri));

        erc20Addr2info[erc20Addr].erc721Addr = erc721Addr;
        erc20Addr2info[erc20Addr].swapRatio = swapRatio;
        erc20Addr2info[erc20Addr].isOriginal = true;

        erc721Addr2info[erc721Addr].erc20Addr = erc20Addr;

        bytes32 salt2 = keccak256(abi.encode(erc721Addr));
        _setRoleAdmin(salt2, DEFAULT_ADMIN_ROLE);

        emit EventUpdateRelation(erc721Addr, erc20Addr, swapRatio, true);
    }

    function emergencyUpdatePair(address erc721Addr, address erc20Addr, uint256 swapRatio,
        bool isOriginalERC20) external onlyOwner lock {

        if (isOriginalERC20) {
            require(IOwner(erc721Addr).owner() == address(this), "NEED OWNER");
        } else {
            require(IOwner(erc20Addr).owner() == address(this), "NEED OWNER");
        }

        erc20Addr2info[erc20Addr].erc721Addr = erc721Addr;
        erc20Addr2info[erc20Addr].swapRatio = swapRatio;
        erc20Addr2info[erc20Addr].isOriginal = isOriginalERC20;

        erc721Addr2info[erc721Addr].erc20Addr = erc20Addr;

        emit EventUpdateRelation(erc721Addr, erc20Addr, swapRatio, isOriginalERC20);

    }

    function swapERC20ToERC721(address erc20Addr, address to) external lock {
        ERC20Info memory erc20Info = erc20Addr2info[erc20Addr];
        ERC721Info memory erc721Info = erc721Addr2info[erc20Info.erc721Addr];

        address erc721Addr = erc20Info.erc721Addr;
        uint256 balance0 = erc20Info.balance;
        uint256 balance1 = IERC20(erc20Addr).balanceOf(address(this));
        uint256 fee = swapFeeRate * 1 * erc20Info.swapRatio / TEN_THOUSAND;

        require((balance1 - balance0 - fee) >= erc20Info.swapRatio , "NOT RECEIVED ENOUGH TOKEN");
        erc20Addr2info[erc20Addr].balance = balance1 - fee;
        _safeTransfer(erc20Addr, fractionxSwapVault, fee);
        uint256 curTokenId;
        if (erc20Info.isOriginal) {
            curTokenId = IFractonXERC721(erc721Addr).mint(to);
        } else {
            IFractonXERC20(erc20Addr).burn(address(this), erc20Info.swapRatio);
            uint256 NFTNumber = erc721Addr2info[erc20Info.erc721Addr].tokenIds.length;
            require(NFTNumber > 0, 'SWAP: NO NFT LEFT');
            uint256 NFTIndex = uint256(blockhash(block.number)) % NFTNumber;
            uint256 NFTID = erc721Info.tokenIds[NFTIndex];
            erc721Addr2info[erc721Addr].tokenIds[NFTIndex] = erc721Addr2info[erc721Addr].tokenIds[NFTNumber - 1];
            erc721Addr2info[erc721Addr].tokenIds.pop();
            curTokenId = NFTID;
            IERC721(erc721Addr).transferFrom(address(this), to, NFTID);
        }
        emit EventSwap(erc721Addr, erc20Addr, 0, balance1 - balance0, curTokenId, 0);
    }

    function setSwapWhiteList(address user, address erc721Addr, bool isGrant) external onlyOwner {
        bytes32 salt = keccak256(abi.encode(erc721Addr));
        if (isGrant) {
            _grantRole(salt, user);
        } else {
            _revokeRole(salt, user);
        }
    }

    function setCloseSwap721To20(uint256 status) external onlyOwner {
        closeSwap721To20 = status;
        emit EventSetCloseSwap721To20(status);
    }

    function setSwapFeeRate(uint256 swapFeeRate2) external onlyOwner {
        swapFeeRate = swapFeeRate2;
        emit EventSetSwapFeeRate(swapFeeRate2);
    }

    function swapERC721ToERC20(address erc721Addr, uint256 tokenId, address to) external lock onlySwapRole(erc721Addr) {
        ERC721Info memory erc721Info = erc721Addr2info[erc721Addr];
        ERC20Info memory erc20Info = erc20Addr2info[erc721Info.erc20Addr];

        address erc20Addr = erc721Info.erc20Addr;
        require(erc721Addr2tokenId2include[erc721Addr][tokenId], "NO RECEIVED TOKEN");
        erc721Addr2tokenId2include[erc721Addr][tokenId] = false;
        if (erc20Info.isOriginal) {
            require(tokenId < IFractonXERC721(erc721Addr).tokenId(), "INVALID TOKENID");
        } else {
            require(IERC721(erc721Addr).ownerOf(tokenId) == address(this), "INVALID TOKENID");
        }
        uint256 amountERC20 = erc20Info.swapRatio;
        if (erc20Info.isOriginal) {
            erc20Addr2info[erc20Addr].balance -= amountERC20;
            _safeTransfer(erc20Addr, to, amountERC20);
        } else {
            IFractonXERC20(erc20Addr).mint(to, amountERC20);
        }
        emit EventSwap(erc721Addr, erc20Addr, tokenId, 0, 0, amountERC20);
    }

    function setTransferFee(address erc20Addr, uint256 fee) external onlyOwner {
        IFractonXERC20(erc20Addr).setFee(fee);
        emit EventSetTransferFee(erc20Addr, fee);
    }

    function set721URI(address erc721Addr, string calldata uri) external onlyOwner {
        IFractonXERC721(erc721Addr).setTokenURI(uri);
        emit EventSetURI(erc721Addr, uri);
    }

    function setFractonXVault(address transVault, address swapVault) external {
        fractionxTransVault = transVault;
        fractionxSwapVault = swapVault;
        emit EventSetFractonXVault(transVault, swapVault);
    }

    function _getERC20Bytecode(string memory name, string memory symbol, uint256 fee) internal pure returns (bytes memory) {
        bytes memory bytecode = type(FractonXERC20).creationCode;
        return abi.encodePacked(bytecode, abi.encode(name, symbol, fee));
    }

    function _getERC721Bytecode(string memory name_, string memory symbol_, string memory tokenUri) internal pure returns (bytes memory) {
        bytes memory bytecode = type(FractonXERC721).creationCode;
        return abi.encodePacked(bytecode, abi.encode(name_, symbol_, tokenUri));
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(ERC20_TRANSFER_SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER FAILED');
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4) {
        erc721Addr2tokenId2include[msg.sender][tokenId] = true;
        if (erc20Addr2info[erc721Addr2info[msg.sender].erc20Addr].isOriginal) {
            IFractonXERC721(msg.sender).burn(tokenId);
        } else {
            erc721Addr2info[msg.sender].tokenIds.push(tokenId);
        }
        return super.onERC721Received(operator, from, tokenId, data);
    }

    function numberOfNFT(address NFTContract) external view returns (uint256) {
        return erc721Addr2info[NFTContract].tokenIds.length;
    }

    function getERC20Info(address erc20Addr) external view returns(ERC20Info memory erc20Info) {
        erc20Info = erc20Addr2info[erc20Addr];
    }
    function getERC721Info(address erc721Addr) external view returns(ERC721Info memory erc721Info) {
        erc721Info = erc721Addr2info[erc721Addr];
    }

}