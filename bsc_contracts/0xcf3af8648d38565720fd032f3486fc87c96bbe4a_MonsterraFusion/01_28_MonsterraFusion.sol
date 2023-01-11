//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../interfaces/IERC20Monsterra.sol";
import "../interfaces/IERC721Monsterra.sol";

contract MonsterraFusion is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    ERC721HolderUpgradeable,
    ReentrancyGuardUpgradeable
{
    using ECDSAUpgradeable for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;

    uint256 constant EXPIRE_TIME = 180;

    address public MstrContract;
    address public ElixirContract;
    address private signAddress;

    event Fusion(
        uint256 indexed _fusionID,
        address indexed _address,
        uint256[] _listTokenID,
        address _contractAddress
    );

    function initialize(address _mstrContract, address _elixirContract)
        public
        initializer
    {
        MstrContract = _mstrContract;
        ElixirContract = _elixirContract;
        __Ownable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function updateMstrContract(address _address) external onlyOwner {
        require(_address != address(0), "invalid-address");
        MstrContract = _address;
    }

    function updateElixirContract(address _address) external onlyOwner {
        require(_address != address(0), "invalid-address");
        ElixirContract = _address;
    }

    function updateSigner(address _address) external onlyOwner {
        require(_address != address(0), "invalid-address");
        signAddress = _address;
    }

    function fusion(
        uint256 _fusionID,
        uint256[] calldata _listTokenID,
        address _contractAddress,
        uint256 _mstrAmount,
        uint256 _elixirAmount,
        uint256 _time,
        bytes calldata _signature
    ) external whenNotPaused nonReentrant {
        require(_time + EXPIRE_TIME > block.timestamp, "signature-expired");
        for (uint256 index = 0; index < _listTokenID.length; index++) {
            uint256 balance;
            balance = (IERC721Upgradeable(_contractAddress).ownerOf(
                _listTokenID[index]
            ) == msg.sender)
                ? 1
                : 0;
            require(balance > 0, "Insufficient-token-balance");
        }
        require(
            verify(
                _fusionID,
                _listTokenID,
                _contractAddress,
                _time,
                _mstrAmount,
                _elixirAmount,
                _signature
            ),
            "invalid-signature"
        );
        burnNFT(_listTokenID, _contractAddress);
        if (_elixirAmount > 0) {
            burnToken(_elixirAmount, ElixirContract);
        }
        if (_mstrAmount > 0) {
            IERC20Upgradeable(MstrContract).safeTransferFrom(
                msg.sender,
                address(this),
                _mstrAmount
            );
        }

        emit Fusion(_fusionID, msg.sender, _listTokenID, _contractAddress);
    }

    function burnToken(uint256 _amount, address _contractAddress) private {
        IERC20Monsterra(_contractAddress).burnFrom(_amount, msg.sender);
    }

    function burnNFT(uint256[] calldata _listTokenID, address _contractAddress)
        private
    {
        IERC721Monsterra(_contractAddress).burnBatch(_listTokenID);
    }

    function verify(
        uint256 _fusionID,
        uint256[] calldata _listTokenID,
        address _contractAddress,
        uint256 _time,
        uint256 _mstrAmount,
        uint256 _elixirAmount,
        bytes calldata _signature
    ) public view returns (bool) {
        bytes32 hashMessage = keccak256(
            abi.encodePacked(
                msg.sender,
                address(this),
                _fusionID,
                _listTokenID,
                _contractAddress,
                _time,
                _mstrAmount,
                _elixirAmount
            )
        );
        address recoverAddress = hashMessage.toEthSignedMessageHash().recover(
            _signature
        );
        return recoverAddress == signAddress;
    }
}