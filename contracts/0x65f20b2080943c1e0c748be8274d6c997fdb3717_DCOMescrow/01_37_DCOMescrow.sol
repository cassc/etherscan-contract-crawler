//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./DecommBadge.sol";
import "./DecommNFT.sol";
import "./libs/IMint.sol";

contract DCOMescrow is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    string public brandName;
    address public brandAddress;
    uint256 public totalNativeTokenDeposite;

    mapping(address => uint256) private deposits;
    mapping(address => CountersUpgradeable.Counter) private _nonces;

    address[10] public admins;
    uint8 adminCount;

    event DepositedNative(address indexed payee, uint256 amount);
    event Deposited(
        address indexed token,
        address indexed payee,
        uint256 amount
    );

    event Withdrawn(
        address indexed token,
        address indexed payee,
        uint256 amount
    );

    event AdminAdded(address indexed adminAddress, uint256 timestamp);
    event AdminRemoved(address indexed adminAddress, uint256 timestamp);

    event TokenAirdropped(
        address indexed token,
        address indexed payee,
        uint256 amount
    );

    event BadgeCreated(
        address indexed contractAddress,
        string name,
        string symbol,
        uint256 mintableLimit,
        uint256 createdAt
    );

    event NFTCreated(
        address indexed contractAddress,
        string name,
        string symbol,
        uint256 mintableLimit,
        uint256 createdAt
    );

    modifier onlyAdmin() {
        bool result = false;
        for (uint8 i = 0; i < adminCount; i++)
            result = result || (msg.sender == admins[i]);

        require(result, "Only brand admin");
        _;
    }

    function initialize(
        string memory _brandName,
        address _firstAdmin
    ) public initializer {
        adminCount = 0;
        brandName = _brandName;
        __Ownable_init();
        __ReentrancyGuard_init();
        _addAdmin(_firstAdmin);
    }

    function _addAdmin(address _adminAddress) internal {
        admins[adminCount] = _adminAddress;
        adminCount++;
        emit AdminAdded(_adminAddress, block.timestamp);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address user) public view returns (uint256) {
        return _nonces[user].current();
    }

    /**
     *@dev receive method to deposite native tokens
     */

    receive() external payable {
        totalNativeTokenDeposite += msg.value;
        emit DepositedNative(msg.sender, msg.value);
    }

    /**
     *@dev balanceOf to know the token balance
     *@param _token address of the token
     *@return token balance of the Escrow
     */

    function balanceOf(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    /**
     *@dev depositNative deposite Native tokens in Escrow
     *@param _amount amount to deposite
     */

    function depositNative(uint256 _amount) public payable {
        require(msg.value >= _amount, "insufficient balance");
        totalNativeTokenDeposite += msg.value;
        emit DepositedNative(msg.sender, _amount);
    }

    /**
     *@dev deposit deposite ERC20 tokens in Escrow
     *@param _amount amount to deposite
     *@param _token address of the token
     */

    function deposit(address _token, uint256 _amount) public {
        uint256 allwance = IERC20(_token).allowance(msg.sender, address(this));
        uint256 balance = IERC20(_token).balanceOf(msg.sender);
        require(allwance >= _amount, "please approve the tokens");
        require(balance >= _amount, "insufficient balance");
        deposits[_token] += _amount;
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        emit Deposited(_token, msg.sender, _amount);
    }

    /**
     *@dev verifyAndTransfer send tokens after verify signature
     *@param _tokens address of the token
     *@param _amounts token amount for receiver
     *@param _hashedMessage hash of nonce and amount as a message
     *@param _v,_r and _s values get by signature
     */

    function verifyAndTransfer(
        uint256 _deadline,
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        bytes32 _hashedMessage,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public {
        require(block.timestamp <= _deadline, "ERC20Permit: expired deadline");
        CountersUpgradeable.Counter storage nonce = _nonces[msg.sender];
        bytes32 hash = keccak256(
            abi.encodePacked(
                nonce.current(),
                _amounts,
                _deadline,
                msg.sender,
                _tokens
            )
        );
        require(hash == _hashedMessage, "invalid hash");
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(
            abi.encodePacked(prefix, _hashedMessage)
        );
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        require(signer != owner(), "invalid signature");
        for (uint256 i = 0; i < _tokens.length; i++) {
            address _token = _tokens[i];
            uint256 _amount = _amounts[i];
            if (_amount != 0) {
                if (_token == address(0)) {
                    uint256 balance = address(this).balance;
                    require(balance >= _amount, "insufficient balance");
                    payable(msg.sender).transfer(_amount);
                } else {
                    uint256 balance = IERC20(_token).balanceOf(address(this));
                    require(balance >= _amount, "insufficient token balance");
                    IERC20(_token).transfer(msg.sender, _amount);
                }
            } else {
                // treat it as NFT or Badge
                IMint(_token).mint(msg.sender);
            }
        }

        nonce.increment();
    }

    function airdropMultiTokens(
        address[] memory _to,
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) external onlyAdmin nonReentrant {
        require(_tokens.length == _amounts.length, "Token not match!");
        require(_tokens.length == _to.length, "User count not match!");
        require(_tokens.length < 50, "Too many requests");

        for (uint i = 0; i < _to.length; i++) {
            _airdropMultiTokenToUser(_to[i], _tokens[i], _amounts[i]);
        }
    }

    function _airdropMultiTokenToUser(
        address _to,
        address _token,
        uint256 _amount
    ) internal {
        if (_amount == 0) {
            IMint token = IMint(_token);
            token.mint(_to);
            emit TokenAirdropped(_token, _to, 1);
        } else {
            if (_token == address(0)) {
                payable(_to).transfer(_amount);
                emit TokenAirdropped(_token, _to, _amount);
            } else {
                IERC20 token = IERC20(_token);
                token.transfer(_to, _amount);
                emit TokenAirdropped(_token, _to, _amount);
            }
        }
    }

    function withdraw(
        address _token,
        uint256 _amount
    ) external onlyAdmin nonReentrant {
        if (_token == address(0)) {
            payable(msg.sender).transfer(_amount);
        } else {
            IERC20(_token).transfer(msg.sender, _amount);
        }
        emit Withdrawn(_token, msg.sender, _amount);
    }

    function addAdmin(address _newAdminAddress) external onlyAdmin {
        require(adminCount < 10, "Already 10 admins");
        _addAdmin(_newAdminAddress);
    }

    function removeAdmin(address _removeAdminAddress) external onlyAdmin {
        require(adminCount > 1, "There must be at least one admin");
        bool isExist = false;
        uint8 matchIndex = 0;
        for (uint8 i = 0; i < adminCount; i++) {
            if (admins[i] == _removeAdminAddress) {
                isExist = true;
                matchIndex = i;
                break;
            }
        }
        require(isExist, "Address is not in admin list");
        admins[matchIndex] = admins[adminCount - 1];
        adminCount--;
        emit AdminRemoved(_removeAdminAddress, block.timestamp);
    }

    function createNewBadge(
        string memory _name,
        string memory _symbol,
        uint256 _mintableLimit
    ) external onlyAdmin returns (address) {
        DecommBadge newBadge = new DecommBadge(_name, _symbol, _mintableLimit);
        emit BadgeCreated(
            address(newBadge),
            _name,
            _symbol,
            _mintableLimit,
            block.timestamp
        );
        return address(newBadge);
    }

    function createNewNFT(
        string memory _name,
        string memory _symbol,
        uint256 _mintableLimit,
        uint96 _feeNumberator
    ) external onlyAdmin returns (address) {
        DecommNFT newNFT = new DecommNFT(_name, _symbol, _mintableLimit);
        newNFT.setDefaultRoyalty(address(this), _feeNumberator);
        emit NFTCreated(
            address(newNFT),
            _name,
            _symbol,
            _mintableLimit,
            block.timestamp
        );
        return address(newNFT);
    }
}