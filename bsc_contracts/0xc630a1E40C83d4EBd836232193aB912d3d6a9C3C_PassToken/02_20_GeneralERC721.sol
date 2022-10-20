// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

contract GeneralERC721 is ERC721Enumerable, ERC2981, Ownable, Pausable {
    using Strings for uint256;
    uint256 public MAX_SUPPLY;
    uint256 internal _totalSupply;
    string private baseURI;

    modifier CheckSupply(uint256 amount) {
        require(amount > 0, "Invalid Amount");
        require(
            MAX_SUPPLY == 0 || totalSupply() + amount <= MAX_SUPPLY,
            "Over_Max_Supply"
        );
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address _recipient,
        uint256 _maxSupply
    ) ERC721(name, symbol) {
        MAX_SUPPLY = _maxSupply;
        _setDefaultRoyalty(_recipient, 750); // 75%
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        require(
            MAX_SUPPLY != 0 &&
                _newMaxSupply < MAX_SUPPLY &&
                _newMaxSupply > totalSupply(),
            "The new value must be less than the original value and not less than the existing total"
        );
        MAX_SUPPLY = _newMaxSupply;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        return baseURI;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        super._setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @notice View supply cap
     */
    function maxSUPPLY() external view returns (uint256) {
        return MAX_SUPPLY;
    }

    function setBaseURI(string memory _tokenURI) external onlyOwner {
        baseURI = _tokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // setting for pause
    function pause() external virtual onlyOwner{
        super._pause();
    }

    function unpause() external virtual onlyOwner{
        super._unpause();
    }
}