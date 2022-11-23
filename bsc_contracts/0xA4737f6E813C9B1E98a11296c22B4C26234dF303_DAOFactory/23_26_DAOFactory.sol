//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.9;

import "./interfaces/IDAOBase.sol";
import "./interfaces/IERC20Base.sol";
import "./interfaces/IDAOFactory.sol";
import '@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol';
import '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import '@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

contract DAOFactory is OwnableUpgradeable, IDAOFactory {
    using ClonesUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public proxyAdminAddress;

    address public daoImpl;
    mapping(string => bool) public handles;
    mapping(address => bool) private _signers;
    mapping(address => bool) private _daoAddresses;
    mapping(address => uint256) public nonces;

    address public tokenImpl;
    mapping(address => string) public logoURLs;
    mapping(address => Reserve[]) public reserves;
    mapping(address => address[]) public tokensByAccount;

    event CreateDAO(uint256 indexed handler, address indexed creator, address indexed daoAddress, uint256 chainId, address tokenAddress);

    event CreateERC20(address indexed creator, address token);
    event ClaimReserve(address indexed account, address indexed token, uint256 amount);

    event SignerSet(address indexed account, bool enable);

    constructor() { }

    function initialize(address daoImpl_, address tokenImpl_) external initializer {
        daoImpl = daoImpl_;
        tokenImpl = tokenImpl_;
        OwnableUpgradeable.__Ownable_init();

        ProxyAdmin _proxyAdmin = new ProxyAdmin();
        proxyAdminAddress = address(_proxyAdmin);
    }

    modifier onlyDao() {
        require(_daoAddresses[msg.sender], 'DAOFactory: caller not a dao address.');
        _;
    }

    function setDaoImpl(address daoImpl_) onlyOwner external {
        daoImpl = daoImpl_;
    }

    function setTokenImpl(address tokenImpl_) onlyOwner external {
        tokenImpl = tokenImpl_;
    }

    function setSigner(address signer_, bool enable_) onlyOwner external {
        _signers[signer_] = enable_;

        emit SignerSet(signer_, enable_);
    }

    function isSigner(address signer_) public override view returns (bool) {
        return _signers[signer_];
    }

    function increaseNonce(address account_) onlyDao external returns (uint256 _nonce) {
        _nonce = nonces[account_];
        nonces[account_]++;
    }

    function createDAO(
        IDAOBase.General calldata general_,
        IDAOBase.Token calldata token_,
        IDAOBase.Governance calldata governance_,
        uint256 deadline_,  // block number
        bytes calldata signature_
    ) external {
        require(deadline_ >= block.number, 'DAOFactory: signature was expired.');
        require(!handles[general_.handle], 'DAOFactory: handle is already taken.');

        bytes32 _handleHash = keccak256(abi.encodePacked(general_.handle));
        bytes32 _hash = ECDSAUpgradeable.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    block.chainid,
                    deadline_,
                    _handleHash
                )
            )
        );
        require(isSigner(ECDSAUpgradeable.recover(_hash, signature_)), 'DAOFactory: invalid signer.');

        // address _daoAddress = daoImpl.clone();
        // IDAOBase(_daoAddress).initialize(general_, token_, governance_);
        // OwnableUpgradeable(_daoAddress).transferOwnership(msg.sender);

        // using proxy
        TransparentUpgradeableProxy _proxy = new TransparentUpgradeableProxy(daoImpl, proxyAdminAddress, '');
        IDAOBase(address(_proxy)).initialize(general_, token_, governance_);
        OwnableUpgradeable(address(_proxy)).transferOwnership(msg.sender);

        handles[general_.handle] = true;
        _daoAddresses[address(_proxy)] = true;

        emit CreateDAO(uint256(_handleHash), msg.sender, address(_proxy), token_.chainId, token_.tokenAddress);
    }

    function upgradeProxy(address payable daoAddress_) external {
        // saving gas
        address _proxyAdminAddress = proxyAdminAddress;
        require(OwnableUpgradeable(daoAddress_).owner() == msg.sender, 'DAOFactory: cannot only upgrade by owner.');
        require(ProxyAdmin(_proxyAdminAddress).getProxyAdmin(TransparentUpgradeableProxy(daoAddress_)) == _proxyAdminAddress, 'DAOFactory: not a valid dao address.');
        require(ProxyAdmin(_proxyAdminAddress).getProxyImplementation(TransparentUpgradeableProxy(daoAddress_)) != daoImpl, 'DAOFactory: already up-to-date.');

        ProxyAdmin(_proxyAdminAddress).upgrade(TransparentUpgradeableProxy(daoAddress_), daoImpl);
    }

    function createERC20(
        string memory name_,
        string memory symbol_,
        string memory logoUrl_,
        uint8 decimal_,
        uint256 totalSupply_,
        DistributionParam[] calldata distributions_
    ) external {
        address _token = tokenImpl.clone();
        IERC20Base(_token).initialize(name_, symbol_, decimal_, totalSupply_);
        logoURLs[_token] = logoUrl_;
        tokensByAccount[msg.sender].push(_token);

        // distribute
        uint256 _distributedAmount = 0;
        for (uint256 index = 0; index < distributions_.length; index++) {
            DistributionParam calldata _distribution = distributions_[index];
            reserves[_distribution.recipient].push(Reserve({
                token: _token,
                amount: _distribution.amount,
                lockDate: _distribution.lockDate
            }));
            _distributedAmount += _distribution.amount;
        }
        if (totalSupply_ > _distributedAmount)
            IERC20Upgradeable(_token).safeTransfer(msg.sender, totalSupply_ - _distributedAmount);
        else
            require(totalSupply_ == _distributedAmount, 'DAOFactory: distributed amount exceed totalSupply');

        emit CreateERC20(msg.sender, _token);
    }

    function claimReserve(uint256 index_) external {
        uint256 _length = reserves[msg.sender].length;
        require(index_ < _length, 'DAOFactory: invalid index.');

        Reserve memory _reserve = reserves[msg.sender][index_];
        require(block.timestamp >= _reserve.lockDate, 'DAOFactory: locked.');
        if (index_ < _length - 1)
            reserves[msg.sender][index_] = reserves[msg.sender][_length - 1];
        reserves[msg.sender].pop();

        IERC20Upgradeable(_reserve.token).safeTransfer(msg.sender, _reserve.amount);
        emit ClaimReserve(msg.sender, _reserve.token, _reserve.amount);
    }

    /** ---------- public getting ---------- **/
    function getReserved(address account_) view public returns (Reserve[] memory) {
        return reserves[account_];
    }

}