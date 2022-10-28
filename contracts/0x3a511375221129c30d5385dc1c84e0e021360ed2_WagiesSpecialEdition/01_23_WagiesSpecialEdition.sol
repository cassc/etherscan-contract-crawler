// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

import { IERC721AUpgradeable } from "erc721a-upgradeable/contracts/interfaces/IERC721AUpgradeable.sol";
import { ERC721AUpgradeable } from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import { ERC721AQueryableUpgradeable } from "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ERC2981Upgradeable } from "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import { StringsUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract WagiesSpecialEdition is ERC721AUpgradeable, ERC721AQueryableUpgradeable, OwnableUpgradeable, ERC2981Upgradeable, UUPSUpgradeable {
    using StringsUpgradeable for uint256;

    /* Errors */

    error NoBurningAllowed();

    /* Storage */

    string _baseUriPrefix;
    string _baseUriSuffix;
    string _contractUri;

    bool _burningEnabled;

    mapping(address => bool) _isMinter;

    constructor() {
        _disableInitializers();
    }

    function initialize() external initializerERC721A initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ERC721A_init("WAGIES Special Edition", "WAGIES SE");
        __ERC2981_init();
        __ERC721AQueryable_init();

        _baseUriPrefix = "https://storage.googleapis.com/storage/v1/b/wagies/o/metadata-se%2F";
        _baseUriSuffix = ".json?alt=media";

        _contractUri = "https://storage.googleapis.com/storage/v1/b/wagies/o/contract-se.json?alt=media";

        _setDefaultRoyalty(0x032171e9e94780015e60cb553A39D63a36663E8D, 300);
    }

    /* Modifiers */

    modifier onlyMinter() {
        if (!(_isMinter[msg.sender] || msg.sender == owner())) revert();
        _;
    }

    /* Non-view functions */

    function mint(address to, uint256 amount) external onlyMinter {
        while(amount > 0) {
            uint256 batchAmount = _min(amount, 6);
            amount -= batchAmount;
            _mint(to, batchAmount);
        }
    }

    function burn(uint256[] calldata ids) external {
        if (_burningEnabled == false) revert NoBurningAllowed();

        unchecked {
            for (uint256 i = 0; i < ids.length; i++) {
                _burn(ids[i], true);
            }
        }
    }

    /* View functions */

    function isBurningEnabled() external view returns (bool) {
        return _burningEnabled;
    }

    function amountMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function tokenURI(uint256 id) public view override(ERC721AUpgradeable, IERC721AUpgradeable) returns(string memory) {
        return string(abi.encodePacked(_baseUriPrefix, id.toString(), _baseUriSuffix));
    }

    function contractURI() external view returns(string memory) {
        return _contractUri;
    }

    /* onlyOwner functions */

    function setMinter(address[] calldata minters, bool[] calldata isEnabler) external onlyOwner {
        if(minters.length != isEnabler.length) revert();
        for(uint i = 0; i < minters.length; i++ ) {
            _isMinter[minters[i]] = isEnabler[i];
        }
    }

    function toggleBurning() external onlyOwner {
        _burningEnabled = !_burningEnabled;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumberator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumberator);
    }

    function setBaseURI(string calldata prefix, string calldata suffix) external onlyOwner {
        _baseUriPrefix = prefix;
        _baseUriSuffix = suffix;
    }

    function setContractURI(string calldata contractUri) external onlyOwner {
        _contractUri = contractUri;
    }

    function withdraw(address to) external onlyOwner {
        (bool success, ) = to.call{ value: address(this).balance }("");
        if (success == false) revert();
    }

    /* Internal functions */

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @dev Used for UUPS upgradability, if removed upgradability is no longer possible for the proxy
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721AUpgradeable, IERC721AUpgradeable, ERC2981Upgradeable) returns (bool) {
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }
}