// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol';
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


contract IDOUpgradeable is OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Permit;

    mapping(uint256 => bytes32) private randomSeeds;
    mapping(bytes32 => bool) public signatures;
    address public marketAddress;
    address public idoAdmin;

    event RandomSeedUpdated(
        uint256 idoNumber,
        bytes32 seed
    );
    event Claimed(
        address indexed receiver,
        uint256 tokenAmount,
        uint256 baseTokenAmount,
        uint256 idoNumber,
        uint256 idoBatchNumber
    );
    event Withdrawl(
        address indexed receiver,
        address indexed token,
        uint256 amount
    );

    modifier onlyAdmin() {
        require(msg.sender == idoAdmin, "ERROR:not admin");
        _;
    }

    function initialize(address _idoAdmin, address _marketAddress) external initializer {
        OwnableUpgradeable.__Ownable_init();
        idoAdmin = _idoAdmin;
        marketAddress = _marketAddress;
    }

    function setIdoAdmin(address _idoAdmin) external onlyOwner {
        idoAdmin = _idoAdmin;
    }

    function setMarketAddress(address _marketAddress) external onlyOwner {
        marketAddress = _marketAddress;
    }

    function setRandomSeed(uint256 idoNumber, bytes32 seed) external onlyAdmin {
        require(seed != 0, "ERROR: seed should not be zero");
        require(randomSeeds[idoNumber] == 0, "ERROR: seed has been already set");
        randomSeeds[idoNumber] = seed;
        emit RandomSeedUpdated(idoNumber, seed);
    }

    function getRandomSeed(uint256 idoNumber) external view returns (bytes32 seed) {
        return randomSeeds[idoNumber];
    }

    function claim(
        uint256 idoNumber,
        uint256 idoBatchNumber,
        address userAddress,
        address idoTokenAddress,
        address baseTokenAddress,
        uint256 idoTokenAmount,
        uint256 baseTokenAmount,
        uint256 deadline,
        bytes memory idoTokenSignature) external onlyAdmin {

        {
            require(block.timestamp <= deadline, "ERROR:time has passed");
            require(idoTokenSignature.length == 65 || idoTokenSignature.length == 0, "invalid signature length");
            bytes32 signature = _getHash(idoNumber, idoBatchNumber, userAddress, idoTokenAddress);
            require(!signatures[signature], "ERROR: has been claimed");
            signatures[signature] = true;
        }

        {
            if (idoTokenSignature.length == 65 && baseTokenAmount > 0) {
                (bytes32 r, bytes32 s, uint8 v) = _splitSignature(idoTokenSignature);
                IERC20Permit(baseTokenAddress).safePermit(userAddress, address(this), baseTokenAmount, deadline, v, r, s);
            }
            if (baseTokenAmount > 0) {
                IERC20(baseTokenAddress).safeTransferFrom(userAddress, address(this), baseTokenAmount);
            }
        }
        IERC20(idoTokenAddress).safeTransfer(userAddress, idoTokenAmount);

        emit Claimed(userAddress, idoTokenAmount, baseTokenAmount, idoNumber, idoBatchNumber);
    }

    function _splitSignature(bytes memory _signature)
    internal pure returns (bytes32 r, bytes32 s, uint8 v){
        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }
    }

    function _getHash(uint256 _idoNumber, uint256 _idoBatchNumber, address _userAddress, address _tokenAddress) internal pure returns (bytes32 signature) {
        return keccak256(abi.encode(_idoNumber, _idoBatchNumber, _userAddress, _tokenAddress));
    }

    function withdraw(address _tokenAddress, uint256 _amount) external {
        require(msg.sender == marketAddress, "ERROR: caller is not the market address");
        require(address(_tokenAddress) != address(0), "ERROR: token address is address(0)");
        require(_amount > 0, "ERROR: amount must be greater than zero");
        uint256 tokenBalance = IERC20(_tokenAddress).balanceOf(address(this));
        require(tokenBalance >= _amount, "ERROR: transfer amount exceeds balance");
        IERC20(_tokenAddress).safeTransfer(msg.sender, _amount);
        emit Withdrawl(msg.sender, _tokenAddress, _amount);
    }


}