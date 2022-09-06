// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract EsionCollectibles is ERC1155Upgradeable, ERC2981Upgradeable, OwnableUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    string private metadataUri;
    using Strings for uint256;

    function initialize(
        string memory _metadataUri,
        address _royaltyReceiver,
        uint96 _royaltyFeeNumerator
    ) public initializer {
        __ERC1155_init(_metadataUri);
        __Ownable_init();
        _setDefaultRoyalty(_royaltyReceiver, _royaltyFeeNumerator);
        metadataUri = _metadataUri;
    }

    function uri(uint256 _id) public view virtual override returns (string memory) {
        return string(abi.encodePacked(metadataUri, _id.toString()));
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(metadataUri, "contractURI"));
    }

    function setMetadataUri(string calldata _metadataUri) external onlyOwner {
        metadataUri = _metadataUri;
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external onlyOwner {
        _burn(from, id, amount);
    }

    function mint(uint256 id, uint256 amount) external onlyOwner {
        _mint(msg.sender, id, amount, "");
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) {
            revert("Ether transfer failed");
        }
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        super._setDefaultRoyalty(receiver, feeNumerator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}