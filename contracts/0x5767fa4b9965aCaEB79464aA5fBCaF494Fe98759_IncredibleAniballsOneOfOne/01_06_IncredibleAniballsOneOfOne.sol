// SPDX-License-Identifier: UNLICENSED
/*
  __    _____  ___    ______    _______    _______  ________   __     _______   ___       _______
 |" \  (\"   \|"  \  /" _  "\  /"      \  /"     "||"      "\ |" \   |   _  "\ |"  |     /"     "|
 ||  | |.\\   \    |(: ( \___)|:        |(: ______)(.  ___  :)||  |  (. |_)  :)||  |    (: ______)
 |:  | |: \.   \\  | \/ \     |_____/   ) \/    |  |: \   ) |||:  |  |:     \/ |:  |     \/    |
 |.  | |.  \    \. | //  \ _   //      /  // ___)_ (| (___\ |||.  |  (|  _  \\  \  |___  // ___)_
 /\  |\|    \    \ |(:   _) \ |:  __   \ (:      "||:       :)/\  |\ |: |_)  :)( \_|:  \(:      "|
(__\_|_)\___|\____\) \_______)|__|  \___) \_______)(________/(__\_|_)(_______/  \_______)\_______)
        __      _____  ___    __     _______       __      ___      ___        ________
       /""\    (\"   \|"  \  |" \   |   _  "\     /""\    |"  |    |"  |      /"       )
      /    \   |.\\   \    | ||  |  (. |_)  :)   /    \   ||  |    ||  |     (:   \___/
     /' /\  \  |: \.   \\  | |:  |  |:     \/   /' /\  \  |:  |    |:  |      \___  \
    /  '__'  \ |.  \    \. | |.  |  (|  _  \\  //  __'  \  \  |___  \  |___    __/  \\
   /   /  \\  \|    \    \ | /\  |\ |: |_)  :)/   /  \\  \( \_|:  \( \_|:  \  /" \   :)
  (___/    \___)\___|\____\)(__\_|_)(_______/(___/    \___)\_______)\_______)(_______/

https://incredible-aniballs.com
*/
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract IncredibleAniballsOneOfOne is ERC721A, Ownable {
    using SafeMath for uint256;

    // ============ Storage ============

    // Base URI for metadata
    mapping(uint256 => string) private _tokenBaseURI;

    // ================================================== //
    //                *** CONSTRUCTOR ***
    // ================================================== //

    constructor(string memory name, string memory symbol)
        ERC721A(name, symbol)
    {}

    // ================================================== //
    //                    *** MINT ***
    // ================================================== //

    /// @notice mintForAddress, called only by owner
    /// @dev mint new NFTs for a given address (for giveaway and partnerships)
    /// @param quantity, number of NFT a mint
    /// @param to, address to mint NFT
    function mintForAddress(uint256 quantity, address to) public onlyOwner {
        _mint(to, quantity);
    }

    // ================================================== //
    //                  *** SETTER ***
    //                    ONLY OWNER
    // ================================================== //

    /// @notice setBaseURI, called only by owner
    /// @dev set Base URI for metadata
    /// @param tokenId, token ID
    /// @param uri, new base URI
    function setBaseURI(uint256 tokenId, string memory uri) external onlyOwner {
        _tokenBaseURI[tokenId] = uri;
    }

    // ================================================== //
    //                *** VIEW METADATA ***
    // ================================================== //

    /// @notice numberMinted
    /// @dev Get the number of NFT minted by a specific address
    /// @param minter, address to check
    /// @return uint256
    function numberMinted(address minter) public view returns (uint256) {
        return _numberMinted(minter);
    }

    /// @notice tokenURI
    /// @dev Get token URI of given token ID. URI will be the _hiddenBaseURI until reveal enabled
    /// @param tokenId, token ID NFT
    /// @return URI
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI(tokenId);

        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
                : "";
    }

    /// @notice walletOfOwner
    /// @dev Get all tokens owned by owner
    /// @param owner, address to check
    /// @return uint256[]
    function walletOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(owner);
        uint256[] memory ownerTokens = new uint256[](ownerTokenCount);
        uint256 ownerTokenIdx = 0;

        for (uint256 tokenIdx = 0; tokenIdx < totalSupply(); tokenIdx++) {
            if (ownerOf(tokenIdx) == owner) {
                ownerTokens[ownerTokenIdx] = tokenIdx;
                ownerTokenIdx++;
            }
        }

        return ownerTokens;
    }

    // ================================================== //
    //             *** INTERNAL FUNCTIONS ***
    // ================================================== //

    /// @notice _baseURI
    /// @dev Get the Base URI for metadata
    /// @param tokenId, token ID
    /// @return string
    function _baseURI(uint256 tokenId)
        internal
        view
        virtual
        returns (string memory)
    {
        return _tokenBaseURI[tokenId];
    }
}