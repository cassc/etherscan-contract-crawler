// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
     __  ____   __ __  ____  ______   ___       ____   __ __  _____ ____  ____     ___  _____ _____     __    __   ___   ___ ___    ___  ____  
    /  ]|    \ |  T  T|    \|      T /   \     |    \ |  T  T/ ___/l    j|    \   /  _]/ ___// ___/    |  T__T  T /   \ |   T   T  /  _]|    \ 
   /  / |  D  )|  |  ||  o  )      |Y     Y    |  o  )|  |  (   \_  |  T |  _  Y /  [_(   \_(   \_     |  |  |  |Y     Y| _   _ | /  [_ |  _  Y
  /  /  |    / |  ~  ||   _/l_j  l_j|  O  |    |     T|  |  |\__  T |  | |  |  |Y    _]\__  T\__  T    |  |  |  ||  O  ||  \_/  |Y    _]|  |  |
 /   \_ |    \ l___, ||  |    |  |  |     |    |  O  ||  :  |/  \ | |  | |  |  ||   [_ /  \ |/  \ |    l  `  '  !|     ||   |   ||   [_ |  |  |
 \     ||  .  Y|     !|  |    |  |  l     !    |     |l     |\    | j  l |  |  ||     T\    |\    |     \      / l     !|   |   ||     T|  |  |
  \____jl__j\_jl____/ l__j    l__j   \___/     l_____j \__,_j \___j|____jl__j__jl_____j \___j \___j      \_/\_/   \___/ l___j___jl_____jl__j__j


Anke, Fulya, Jochen und Jörg <3 Vielen Dank für eure wunderbare Arbeit am crypto business women Projekt, 
ohne euch gäbe es cbw nicht. Anke, mit dir habe ich eine WOW-Unternehmerin und Freundin an meiner Seite, 
uns beiden war vom ersten Augenblick an klar, dass unsere Verbindung ohne ein Enddatum sein wird. Fulya, 
deine Kunst hat das Projekt von Anfang an begleitet, bereichert & inspiriert und ich bin sowas von bereit 
für alle weiteren NFTs. Du hast die cbw Vision sofort erkannt und ohne zu zögern ja gesagt, und dafür danke 
ich dir sehr. Erfolgreiche NFT-Projekte brauchen ganz dringend Künstlerinnen wie dich. Jochen, deine 
Zeichnungen sind einfach unbeschreiblich schön und dein Gefühl fürs Design ist eine sehr einzigartige, 
besondere Gabe. Du bist ein Ästhetik-Wächter mit Ausdauer, ich danke dir für die vielen Stunden, in denen 
du mich von ihrer Bedeutung und ihrer Wirkung überzeugt hast. Danke, dass dir cbw so am Herzen liegt. 
Schatz, ich danke dir von Herzen, dass du dich um den smart contract mit all den Dingen, die dazugehören, 
kümmerst. Du sagtest nicht “das geht nicht”, das tust du nie, ganz gleich wie groß auch immer meine Idee ist, 
mit der ich zu dir komme, egal, wie herausfordernd der Aufwand für dich ist, der aus meinen Ideen resultiert. 
Danke. Ich liebe dich.
*/


import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

/// @custom:security-contact [email protected]
contract CryptoBusinessWomen is ERC1155, ERC2981, Ownable, Pausable, ERC1155Burnable, ERC1155Supply {

    string public name = "cryptobusinesswomen";
    string public symbol = "cbw";
    string public contractUri = "https://nft.crypto-business-women.de/metadaten/cbw_contract_metadata.json"; 


    constructor() ERC1155("https://nft.crypto-business-women.de/metadaten/cbw_nft_metadata_{id}") 
    {
        // ERC2981 Default Royalty for contract-creator set to 10% = 1000 
        _setDefaultRoyalty(msg.sender, 1000);
    }


    // Pausable ---------------------------------------------------------------
    function pause() 
        public 
        onlyOwner 
    {
        _pause();
    }
    // Pausable
    function unpause() 
        public 
        onlyOwner 
    {
        _unpause();
    }

    // ERC1155 ----------------------------------------------------------------
    function setURI(string memory newuri) 
        public 
        onlyOwner 
    {
        _setURI(newuri);
    }
    // ERC1155
    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }
    // ERC1155
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }
    // ERC1155Supply :: handle additionall override  
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // ERC2981 ----------------------------------------------------------------
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) 
        public 
        onlyOwner 
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
    // ERC2981
    function deleteDefaultRoyalty() 
        public 
        onlyOwner 
    {
        _deleteDefaultRoyalty();
    }
    // ERC2981
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) 
        public 
        onlyOwner 
    {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }    
    // ERC2981
    function resetTokenRoyalty(uint256 tokenId) 
        public 
        onlyOwner 
    {
        _resetTokenRoyalty(tokenId);
    }
    // ERC2981 :: handle additionall override
    function supportsInterface(bytes4 interfaceId)
        public 
        view 
        virtual 
        override(ERC1155, ERC2981) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }
    
    // internal convenience functions for CryptoBusinessWomen contract. ----------------
    /**
    *
    *  Bulk minting 'amount[]' new tokens of token type 'id' to adresses 'to[]'.
    *  'amount[]' and 'to[]' are corresponding lists.  
    *
    */
    function bulkMint(address[] memory to, uint256 id, uint256[] memory amount) 
        public 
        onlyOwner
    {
        require(to.length == amount.length, "CryptoBusinessWomen: to[] and amount[] length mismatch");

        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], id, amount[i], "");
        }
    }

    /**
    *
    *  Bulk transfers of 'amount[]' tokens of token type 'id' from adresses 'from' to adresses 'to[]'.
    *  'amount[]' and 'to[]' are corresponding lists
    *  =BulkAirDrop
    *
    */
    function safeBulkTransferFrom(address from, address[] memory to, uint256 id, uint256[] memory amount) 
        public
        onlyOwner  
    {
        require(to.length == amount.length, "CryptoBusinessWomen: to[] and amount[] length mismatch!");

        for (uint256 i = 0; i < to.length; i++) {
            safeTransferFrom(from, to[i], id, amount[i], "");
        }
    }

    function setContractURI(string memory newuri) 
        public 
        onlyOwner 
    {
        contractUri = newuri;
    }
}