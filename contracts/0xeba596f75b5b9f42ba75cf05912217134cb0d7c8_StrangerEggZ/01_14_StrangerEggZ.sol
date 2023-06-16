// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
  _____ __                                      ______           _____
  / ___// /__________ _____  ____ ____  _____   / ____/___ _____ /__  /
  \__ \/ __/ ___/ __ `/ __ \/ __ `/ _ \/ ___/  / __/ / __ `/ __ `/ / / 
 ___/ / /_/ /  / /_/ / / / / /_/ /  __/ /     / /___/ /_/ / /_/ / / /__
/____/\__/_/   \__,_/_/ /_/\__, /\___/_/     /_____/\__, /\__, / /____/
                          /____/                   /____//____/        
*/

/*
* Hi Mom !
* I dedicate this project to you ! If I've made it until here it's thank to you
* Thank you for all the things that you did for me, I know it has been really hard sometimes.
* Now you will be in the blockchain forever !
* I love you with all my heart <3
* MW
*/

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract StrangerEggZ is ERC721Enumerable, Ownable, ERC721URIStorage {
    using Strings for uint256;

    string baseTokenUri;
    bool baseUriDefined = false;
    bool public migrationActive = true;
    
    //EggZ pack unit price
    uint256 private unitPrice1EggPack = 0.06 ether; // 0.06 ether
    uint256 private unitPrice4EggPack = 0.05 ether; // 0.05 ether
    uint256 private unitPrice6EggPack = 0.045 ether; // 0.045 ether
    uint256 private unitPrice12EggPack = 0.035 ether; // 0.035 ether
    
    bool public canMint = false;

    // withdraw addresses
    address artistAdr = 0xb23D2ca9b0CBDDac6DB8A3ACcd13eCb6726d4Ee7;
    address sc_dev = 0xda9d7C1c84c7954Ee7F5281cDCddaD359ee072e6;
    
    address oldCOntractAddress = 0x11957A61aC1684Efa13f421e380857DC32E366C7;
    address burnAddress = 0x000000000000000000000000000000000000dEaD;
    
    
    uint256 NB_MINTED_OLD_CONTRACT = 2876;
    
    /* Migration reserve 2876 */
    uint256 MIGRATION_SUPPLY = 0;
    uint256 MIGRATION_MAX_SUPPLY = NB_MINTED_OLD_CONTRACT;
    
    /* Free EggZ reserve 2876 */
    uint256 FREE_EGG_SUPPLY = 0;
    uint256 FREE_EGG_MAX_SUPPLY = NB_MINTED_OLD_CONTRACT;
    
    /* Normal mint reserve 10000 - (2876 + 2876) = 4248 TOTAL SUPPLY*/
    uint256 NORMAL_MINT_SUPPLY = 0;
    // We have 2876 reserved for already minted EggZ in the old smart contract
    // + we have reserved the same amount to give a free EggZ when migrate
    uint256 NORMAL_MINT_MAX_SUPPLY = 4248;
    
    uint256 NOT_MIG_TOKEN_INDEX = NB_MINTED_OLD_CONTRACT;
    
    function migrationSupply() public view returns(uint256) {
        return MIGRATION_SUPPLY;
    }
    
    function freeEggSupply() public view returns(uint256) {
        return FREE_EGG_SUPPLY;
    }
    
    function normalSupply() public view returns(uint256) {
        return NORMAL_MINT_SUPPLY;
    }
    
    function getNextNonMigratedTokenId() public view returns(uint256) {
        return NOT_MIG_TOKEN_INDEX;
    }
    
    
    constructor(string memory baseURI) ERC721("Stranger EggZ", "SEZ")  {
        setBaseURI(baseURI);
    }
    
    /**********************************************
     * 
     *      MIGRATION
     * 
     * *******************************************/
     
     function burnAndMintNewEgg(uint256 tokenId) external {
        ERC721Enumerable contrat = ERC721Enumerable(oldCOntractAddress);
        require(contrat.ownerOf(tokenId) == msg.sender);
        
        contrat.transferFrom(msg.sender, burnAddress, tokenId);
        require(contrat.ownerOf(tokenId) == burnAddress);
        
        /* Mint the same EggZ from the previous contract */
        mintMigratedEgg(tokenId);
        
        /* Mint a free Egg */
        if(migrationActive) {
            mintFreeEgg();
        }
    }
    
    function migrateEggZ(uint256[] memory tokenIds) external {
        require(tokenIds.length <= 50, "You can migrate maximum 50 EggZ at a time");
        
        burnTokens(tokenIds);
        
        mintEggZOnNewCOntract(tokenIds);
        
        if(migrationActive) {
            mintFreeEggForSender(tokenIds);
        }
    }
    
    function burnTokens(uint256[] memory tokenIds) internal {
        ERC721Enumerable contrat = ERC721Enumerable(oldCOntractAddress);
        
        for(uint256 i; i < tokenIds.length; i++) {
            require(contrat.ownerOf(tokenIds[i]) == msg.sender);
            contrat.transferFrom(msg.sender, burnAddress, tokenIds[i]);
        }
    }
    
    function mintEggZOnNewCOntract(uint256[] memory tokenIds) internal {
        ERC721Enumerable contrat = ERC721Enumerable(oldCOntractAddress);
        
        for(uint256 i; i < tokenIds.length; i++) {
            require(contrat.ownerOf(tokenIds[i]) == burnAddress);
            mintMigratedEgg(tokenIds[i]);
        }
    }
    
    function mintFreeEggForSender(uint256[] memory tokenIds) internal {
        for(uint256 i; i < tokenIds.length; i++) {
            mintFreeEgg();
        }
    }
    
    /*************************************************
     * 
     *      METADATA PART
     * 
     * ***********************************************/
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    /*
    *   The setBaseURI function with a possibility to freeze it !
    */
    function setBaseURI(string memory baseURI) public onlyOwner() {
        require(!baseUriDefined, "Base URI has already been set");
        
        baseTokenUri = baseURI;
        
    }
    
    function lockMetadatas() public onlyOwner() {
        baseUriDefined = true;
    }
    
    function deactivateMigration() public onlyOwner() {
        migrationActive = false;
    }
    
    /*************************************************
     * 
     *      MINT PART
     * 
     * ***********************************************/
    
    /*
    *   Mint one Egg
    */
    function summon1Egg() public payable {
        summonEggZFromSpace(1,unitPrice1EggPack);
    }
    
    /*
    *   Mint a 4 EggZ Pack
    */
    function summon4PackEggZ() public payable {
        summonEggZFromSpace(4,unitPrice4EggPack);
    }
    
    /*
    *   Mint a 6 EggZ Pack
    */
    function summon6PackEggZ() public payable {
        summonEggZFromSpace(6,unitPrice6EggPack);
    }
    
    /*
    *   Mint a 12 EggZ Pack
    */
    function summon12PackEggZ() public payable {
        summonEggZFromSpace(12,unitPrice12EggPack);
    }
    
    /*
    * Mint from reserve only allowed after migration done
    */
    
    /*
    *   Mint one Egg from reserve
    */
    function summon1EggFromReserve() public payable {
        mintInFreeEggZReserve(1,unitPrice1EggPack);
    }
    
    /*
    *   Mint a 4 EggZ Pack from reserve
    */
    function summon4PackEggZromReserve() public payable {
        mintInFreeEggZReserve(4,unitPrice4EggPack);
    }
    
    /*
    *   Mint a 6 EggZ Pack from reserve
    */
    function summon6PackEggZromReserve() public payable {
        mintInFreeEggZReserve(6,unitPrice6EggPack);
    }
    
    /*
    *   Mint a 12 EggZ Pack from reserve
    */
    function summon12PackEggZromReserve() public payable {
        mintInFreeEggZReserve(12,unitPrice12EggPack);
    }
    
    /*
    * The mint function
    */
    function summonEggZFromSpace(uint256 num, uint256 price) internal {
        uint256 supply = totalSupply();
        require( canMint,                              "Sale paused" );
        require( NORMAL_MINT_SUPPLY + num <= NORMAL_MINT_MAX_SUPPLY,  "No EggZ left :'(" );
        require( msg.value >= price * num,             "Not enough ether sent" );

        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, supply + i );
            NORMAL_MINT_SUPPLY++;
            setNotMigTokenId(supply + i);
        }
    }
    
    function mintInFreeEggZReserve(uint256 num, uint256 price) internal {
        uint256 supply = totalSupply();
        require( !migrationActive, "Can't mint the reserve if migration is not active");
        require( FREE_EGG_SUPPLY + num <= FREE_EGG_MAX_SUPPLY, "No EggZ left :'(" );
        require( msg.value >= price * num,             "Not enough ether sent" );

        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, supply + i );
            FREE_EGG_SUPPLY++;
            setNotMigTokenId(supply + i);
        }
    }
    
    
    function mintMigratedEgg(uint256 tokenId) internal {
        uint256 supply = totalSupply();
        require( MIGRATION_SUPPLY < MIGRATION_MAX_SUPPLY, "Migration reserve empty" );
        
        _safeMint( msg.sender, supply);
        MIGRATION_SUPPLY++;
        
        //We have to do this, so the old EggZ have the same metadata in new contract
        _setTokenURI(supply, tokenId.toString());
    }
    
    function mintFreeEgg() internal {
        uint256 supply = totalSupply();
        require( FREE_EGG_SUPPLY < FREE_EGG_MAX_SUPPLY, "No EggZ left :'(" );
        
        _safeMint( msg.sender, supply);
        FREE_EGG_SUPPLY++;
        
        setNotMigTokenId(supply);
    }
    
    
    
    function setNotMigTokenId(uint256 supply) internal {
        _setTokenURI(supply, NOT_MIG_TOKEN_INDEX.toString());
        NOT_MIG_TOKEN_INDEX++;
    }
    
    
    
    function switchMintStatus() public onlyOwner {
        canMint = !canMint;
    }
    
    
    /*************************************************
     * 
     *      UTILITY PART
     * 
     * ***********************************************/
    /* Just in case */
    function update1EggPrice(uint256 price) public onlyOwner() {
        unitPrice1EggPack = price;
    }
    
    function update4EggPrice(uint256 price) public onlyOwner() {
        unitPrice4EggPack = price;
    }
    
    function update6EggPrice(uint256 price) public onlyOwner() {
        unitPrice6EggPack = price;
    }
    
    function update12EggPrice(uint256 price) public onlyOwner() {
        unitPrice12EggPack = price;
    }
    
    
    
    function listEggZOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 _each = address(this).balance / 2;
        require(payable(artistAdr).send(_each));
        require(payable(sc_dev).send(_each));
    }
    
    /*
    *   Overrides to make ERC721Enumerable and ERC721URIStorage compatible
    */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}