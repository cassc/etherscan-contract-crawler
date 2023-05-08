// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ISidGiftCardRegistrar.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract SidGiftCardRegistrar is ERC1155, ISidGiftCardRegistrar, Ownable, Pausable {
    mapping(address => bool) public controllers;

    constructor() ERC1155("") {}

    modifier onlyController() {
        require(controllers[msg.sender], "Not a authorized controller");
        _;
    }

    function setURI(string calldata newURI) external onlyOwner {
        _setURI(newURI);
    }

    function uri(uint256 _id) public view virtual override(ERC1155) returns (string memory) {
        return string(abi.encodePacked(ERC1155.uri(_id), Strings.toString(_id)));
    }

    function name() public view virtual returns (string memory) {
        return "SPACE ID Gift Card";
    }

    function symbol() public view virtual returns (string memory) {
        return "SIDGC";
    }

    function register(
        address to,
        uint256 id,
        uint256 amount
    ) external override onlyController whenNotPaused returns (uint256, uint256) {
        super._mint(to, id, amount, "");
        return (id, amount);
    }

    function batchRegister(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external override onlyController whenNotPaused {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        for (uint256 i = 0; i < ids.length; i++) {
            if (amounts[i] > 0) {
                super._mint(to, ids[i], amounts[i], "");
            }
        }
    }

    function batchBurn(
        address account,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyController whenNotPaused {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        for (uint256 i = 0; i < ids.length; i++) {
            if (amounts[i] > 0) {
                super._burn(account, ids[i], amounts[i]);
            }
        }
    }

    function addController(address controller) external override onlyOwner {
        require(controller != address(0), "address can not be zero!");
        controllers[controller] = true;
        emit ControllerAdded(controller);
    }

    function removeController(address controller) external override onlyOwner {
        require(controller != address(0), "address can not be zero!");
        controllers[controller] = false;
        emit ControllerRemoved(controller);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual whenNotPaused override(ERC1155, IERC1155) {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        for (uint256 i = 0; i < ids.length; i++) {
            if (amounts[i] > 0) {
                super.safeTransferFrom(from, to, ids[i], amounts[i], data);
            }
        }
    }
}