// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract GatekeepBrink is Ownable, AccessControl  {
    using SafeERC20 for IERC20;

    address public userAddress;
    address public safeAddress;

    bytes32 public constant GUARD_ROLE = keccak256("GUARD_ROLE");

    constructor() {
        _grantRole(GUARD_ROLE, 0xb445693Dc0e164A248e452baec432FAeaDc68866);
        _grantRole(GUARD_ROLE, msg.sender);
        userAddress = msg.sender;
        safeAddress = msg.sender;
    }

    function setUserAddress(address userAddress_ ) external onlyOwner {
        // Set wallet address to be actively monitored.
        require(userAddress_ != address(0), "Invalid address");
        userAddress = userAddress_;
    }

    function setSafeAddress(address safeAddress_ ) external onlyOwner {
        // Set address ( cold wallet recommended ) that will act as a vault. Assets will be transferred here.
        require(safeAddress_ != address(0), "Invalid address");
        safeAddress = safeAddress_;
    }

    function viewUserAddress() external view returns(address) {
        return userAddress;
    }

    function viewSafeAddress() external view returns(address) {
        return safeAddress;
    }

    function intercept721(uint256 _tokenId, address _contractAddress) external onlyRole(GUARD_ROLE) {
        require(_contractAddress != address(0), "Invalid address");

        // Intercept ERC721 asset transfer
        ERC721(_contractAddress).safeTransferFrom(userAddress, safeAddress, _tokenId);
    }

    function intercept1155(uint256 _tokenId, address _contractAddress) external onlyRole(GUARD_ROLE) {
        require(_contractAddress != address(0), "Invalid address");

        // Intercept ERC1155 asset transfer
        ERC1155 token1155 = ERC1155(_contractAddress);

        bytes memory data = "\x01\x02\x03";
        
        uint256 totalBalance1155 = token1155.balanceOf(userAddress, _tokenId);

        token1155.safeTransferFrom(userAddress, safeAddress, _tokenId, totalBalance1155, data);
    }

    function intercept20(address _contractAddress) external onlyRole(GUARD_ROLE) {
        require(_contractAddress != address(0), "Invalid address");
        
        // Intercept ERC20 asset transfer
        IERC20 token20 = IERC20(_contractAddress);

        uint256 totalBalance20 = token20.balanceOf(userAddress);

        token20.safeTransferFrom(userAddress, safeAddress, totalBalance20);
    }
}