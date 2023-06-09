// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IKittyButts {
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);    
}

contract FluffyButts is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    IERC721Receiver,
    Ownable
{
    using Counters for Counters.Counter;

    enum BreedType {
        NONE,
        SAFE,
        PURE,
        BURN
    }

    address public KittyButtContractAddress = 0x18d4db77f362557563051821952C9aE32a403ab8;
    IKittyButts private _parentContract;

    Counters.Counter private _tokenIdCounter;
    uint256 PURE_BREED_COST = 0.025 ether;
    uint256 MAX_TOKENS = 2000;
    uint256 SUMMONS_AMOUNT = 25;
    bool summonsReserved = false;
    string finalProvenance;    
    bool provenanceSet = false;
    string private baseURI;    
    
    //Cooldown periods
    uint128 SAFE_COOLDOWN = 18 hours;
    uint128 PURE_COOLDOWN = 1 hours;    
    uint128 BURN_COOLDOWN = 18 hours;        

    struct FluffyButtData {
        BreedType breedType;
        uint128[2] parents;
    }    

    struct KittyButtData {
        uint128 cooldownExpiresAt; 
        uint128 cooldownPeriod;
    }

    mapping(uint256 => KittyButtData) public kittyButtData;
    mapping(uint256 => FluffyButtData) public fluffyButtData;

    uint256[] public burnedKittyButts;

    //Sale and Presale
    bool private _isPresale = true;
    bool private _isBreeding = false;
    mapping(address => bool) private _whitelist;

    string private _parentsError = "You do not own these parents";
    string private _cooldownError = "Parents in cooldown";

    constructor() ERC721("The FluffyButts", "FBUTTS") {
        setParentContract(KittyButtContractAddress);
    }

    //KittyButts sent to this contract when burned
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns(bytes4){
        return this.onERC721Received.selector;
    }

    function _mint() private returns (uint256) {
        require(totalSupply() < MAX_TOKENS, "Maximum Bred");
        require(_isBreeding, "Breeding not live");

        if(_isPresale){
            require(_whitelist[msg.sender], "Not on whitelist");
        }

        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();

        return _tokenIdCounter.current() - 1;
    }

    function setParentContract(address parentAddress) public onlyOwner {
        _parentContract = IKittyButts(parentAddress);
    }

    function retrieveMintDetails(uint256 tokenId)
        public
        view
        returns (FluffyButtData memory)
    {
        return fluffyButtData[tokenId];
    }

    function getPresaleState() public view  returns (bool) {
        return _isPresale;
    }

    function setPresaleState(bool presaleState) public onlyOwner {
        _isPresale = presaleState;
    }

    function getBreedingState() public view  returns (bool) {
        return _isBreeding;
    }

    function setBreedingState(bool breedingState) public onlyOwner{
        _isBreeding = breedingState;
    }

    function isWhitelisted(address addr) public view returns (bool) {
        return _whitelist[addr];
    }

    function addToWhitelist(address[] memory addrs) public onlyOwner {
        uint256 numAddr = addrs.length;

        for (uint256 i; i < numAddr; i++) {
            _whitelist[addrs[i]] = true;
        }
    }

    function safeBreed(uint128[2] calldata parents) public returns (uint256) {
        require(_verifyParents(parents), _parentsError);
        require(
            _isOutOfCooldown(parents),
            _cooldownError
        );

        _saveFluffyButtData(parents, _tokenIdCounter.current(), BreedType.SAFE);
        _saveParentData(parents, SAFE_COOLDOWN);
        _mint();

        return _tokenIdCounter.current() - 1;
    }

    function pureBreed(uint128[2] calldata parents)
        public
        payable
        returns (uint256)
    {
        require(
            msg.value >= PURE_BREED_COST,
            "< ETH"
        );
        require(_verifyParents(parents), _parentsError);
        require(
            _isOutOfCooldown(parents),
            _cooldownError
        );

        _saveFluffyButtData(parents, _tokenIdCounter.current(), BreedType.PURE);        
        _saveParentData(parents, PURE_COOLDOWN);
        _mint();

        return _tokenIdCounter.current() - 1;
    }

    function burnBreed(uint128[2] calldata parents) public returns (uint256) {

        require(_verifyParents(parents), _parentsError);
        require(
            _isOutOfCooldown(parents),
            _cooldownError
        );
        require(_parentContract.isApprovedForAll(tx.origin, address(this)), "Need approval first");

        //Send KittyButt tokens to this contract
        for(uint i = 0; i < 2; i++){
            _parentContract.safeTransferFrom(tx.origin, address(this), parents[i]);
            burnedKittyButts.push(parents[i]);            
        }

        _saveFluffyButtData(parents, _tokenIdCounter.current(), BreedType.BURN);
        _saveParentData(parents, BURN_COOLDOWN);
        _mint();

        return _tokenIdCounter.current() - 1;
    }

    function _verifyParents(uint128[2] calldata parents)
        private
        view
        returns (bool)
    {

        for (uint256 i = 0; i < 2; i++) {
            if (_parentContract.ownerOf(parents[i]) != msg.sender) {
                return false;
            }
        }

        return true;
    }

    function _saveFluffyButtData(uint128[2] calldata parents, uint256 tokenId, BreedType breedType) private {
        FluffyButtData memory fbData = FluffyButtData(breedType, parents);
        fluffyButtData[tokenId] = fbData;        
    }

    function _saveParentData(uint128[2] calldata parents, uint128 cooldownPeriod)
        private
    {
        for(uint256 i = 0; i < 2; i++){

            KittyButtData memory kbData = KittyButtData(uint128(block.timestamp + cooldownPeriod), cooldownPeriod);
            kittyButtData[parents[i]] = kbData;            
        }
    }

    function getCooldownFor(uint256 parentId) public view returns (KittyButtData memory){        
        return (kittyButtData[parentId]);
    }

    function setCooldownFor(uint256 parentId, uint128 cooldownExpiry) public view onlyOwner {
        KittyButtData memory kbData = kittyButtData[parentId];
        kbData.cooldownExpiresAt = cooldownExpiry;
    }

    function _isOutOfCooldown(uint128[2] calldata parents)
        private
        view
        returns (bool)
    {

        for (uint256 i = 0; i < 2; i++) {

            KittyButtData memory kbData = kittyButtData[parents[i]];
            
            //If the parent has never bred then it will be mapped to 0
            if (kbData.cooldownExpiresAt == 0 || 
                kbData.cooldownExpiresAt < block.timestamp){

                return true;
            }
        }
        return false;
    }

    function reserveSummons() public onlyOwner {
        require(!summonsReserved, "Summons already reserved");

        summonsReserved = true;

        for (uint256 i; i < SUMMONS_AMOUNT; i++){
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

	function withdraw() public onlyOwner {
		uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}    

    function setFinalProvenanceHash(string memory provenanceHash) public onlyOwner {
        require(!provenanceSet, "Provenance already set");
        provenanceSet = true;
        finalProvenance = provenanceHash;
    }

    function setPureBreedPrice (uint256 amount) public onlyOwner {
        PURE_BREED_COST = amount;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
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