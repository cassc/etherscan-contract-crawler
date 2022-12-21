// SPDX-License-Identifier: NONE
pragma solidity 0.8.10;
import "./OpenzeppelinERC721.sol";
import "./OpenZeppelinMerkleProof.sol";

contract MetaaniDNA is ERC721Enumerable {
    uint public constant price = 0.075 ether;
    string private _baseBeforeRevealURI = "ipfs://QmdXrwGLHBJSft1CBrps4XhZfxEHJ3GCwuCvf3ihffKuDn/";
    uint public teamMintedAmount = 0;
    string private _ipfs_base;
    bool public isRevealed = false;
    bool public isFrozenBaseURI = false;
    uint private tokenIdCount = 1;
    uint public  tokenIdCountMax = 3000;
    mapping(uint => bool) public minted;
    uint public privateAmountLimit = 50;
    uint public publicAmountLimit = 3000;
    bytes32 public allowListRoot = 0x493c228601905ea40eec37ae8423c901976d08e0ea1f9fa6fdc0924ea7633f58;
    enum MintTermStatus{
        None,             
        holderSale,       
        allowListSale,    
        publicSale        
    }
    MintTermStatus private _mintTermStatus = MintTermStatus.None;
    mapping( address => uint ) public addressMintedMap1;
    mapping( address => uint ) public addressMintedMap2;
    mapping( address => uint ) public addressMintedMap3;

    address owner;                                                                      
    address constant fundsWallet           = 0x8837391C2634b62C4fCF4f0b01F0772A743A4Cf3;
    address constant fundsRescueSpareKey   = 0xbDc378A75Fe1d1b53AdB3025541174B79474845b;
    address constant fundsRescueDestWallet = 0xeecE4544101f7C7198157c74A1cBfE12aa86718B;



    function setRoot(bytes32 _merkleroot) public {
        require( _msgSender() == owner );
        allowListRoot = _merkleroot;
    }

    function setPrivateAmountLimit(uint amountLimit) public {
        require(_msgSender() == owner);
        privateAmountLimit = amountLimit;
    }

    function setPublicAmountLimit(uint amountLimit) public {
        require(_msgSender() == owner);
        publicAmountLimit = amountLimit;
    }

    function checkredeem(address account, uint256 allowedAmount, bytes32[] calldata proof) public view returns ( uint ) {
        if (_verify(_leaf(account, allowedAmount), proof)){
            return allowedAmount;
        } else {
            return 0;
        }
    }

    function _leaf(address account, uint256 allowedAmount) internal pure returns (bytes32){
        return keccak256(abi.encodePacked(account , allowedAmount));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool){
        return MerkleProof.verify(proof, allowListRoot, leaf);
    }
    
    function holderSale(address account, uint256 allowedAmount, bytes32[] calldata proof) public payable {
        require( msg.value == price , "Invalid ETH");
        require(checkredeem( account , allowedAmount , proof ) > 0 , "account is not in allowlist");
        require( _msgSender() == account);
        require( _mintTermStatus == MintTermStatus.holderSale , "MintTermStatus Invalid");
        require(tokenIdCount <= tokenIdCountMax, "out of stock");
        require(addressMintedMap1[account] < allowedAmount, "amount limited in AL");
        require(addressMintedMap1[account] < privateAmountLimit, "amount limited at this time");
        _safeMint( account , tokenIdCount);
        addressMintedMap1[account]++;
        minted[tokenIdCount] = true;
        tokenIdCount++;
    }

    function allowListSale(address account, uint256 allowedAmount, bytes32[] calldata proof) public payable{
        require( msg.value == price , "Invalid ETH");
        require(checkredeem( account , allowedAmount , proof ) > 0 , "account is not in allowlist");
        require( _msgSender() == account);
        require( _mintTermStatus == MintTermStatus.allowListSale , "MintTermStatus Invalid");
        require(tokenIdCount <= tokenIdCountMax, "out of stock");
        require(addressMintedMap2[account] < allowedAmount, "amount limited in AL");
        require(addressMintedMap2[account] < privateAmountLimit, "amount limited at this time");
        _safeMint( account , tokenIdCount);
        addressMintedMap2[account]++;
        minted[tokenIdCount] = true;
        tokenIdCount++;
    }

    function publicSale(uint requestAmount) public payable{
        require( msg.value == price * requestAmount , "Invalid ETH");
        address account = _msgSender();
        require( _mintTermStatus == MintTermStatus.publicSale , "MintTermStatus Invalid");
        for(uint i=0; i<requestAmount; i++){
            require(tokenIdCount <= tokenIdCountMax, "out of stock");
            require(addressMintedMap3[account] < publicAmountLimit, "amount limited at this time");
            _safeMint( account , tokenIdCount);
            addressMintedMap3[account]++;
            minted[tokenIdCount] = true;
            tokenIdCount++;
        }
    }

    function teamMint(uint requestAmount) public {
        address account = _msgSender();
        require(account == owner );
        for(uint i=0; i<requestAmount; i++){
            require(teamMintedAmount < 300, "out of team stock");
            require(tokenIdCount <= tokenIdCountMax, "out of stock");
            teamMintedAmount++;
            _safeMint( account , tokenIdCount);
            addressMintedMap1[account]++;
            minted[tokenIdCount] = true;
            tokenIdCount++;
        }
    }

    function getMintTermStatus() public view returns (MintTermStatus) {
        return _mintTermStatus;
    }

    function setMintTermStatus(MintTermStatus status) public {
        require(_msgSender() == owner );
        _mintTermStatus = status;
    }

    function withdraw() public {
        require(msg.sender == fundsWallet);
        uint balance = address(this).balance;
        payable(fundsWallet).transfer(balance);
    }

    function withdrawSpare() public {
        require(msg.sender == fundsRescueSpareKey);
        uint balance = address(this).balance;
        payable(fundsRescueDestWallet).transfer(balance);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }


    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function burn(uint256 _id) public {
        require( msg.sender == ownerOf(_id));
        _burn(_id);
    }

    function _baseURI() internal view override returns (string memory) {
        return _ipfs_base;
    }

    function freezeBaseURI() external {
        require(msg.sender == owner );
        require(bytes(_baseURI()).length > 0, "baseURI is EMPTY");
        require(tokenIdCount >= tokenIdCountMax, "Not Reached Amount");
        isFrozenBaseURI = true;
    }

    function _baseURIBeforeReveal() internal view returns (string memory) {
        return _baseBeforeRevealURI;
    }

    function setBaseURI(string memory baseMetadataURI) external{
        require(msg.sender == owner );
        require(isFrozenBaseURI == false, "Metadata is Frozen");
        _ipfs_base = baseMetadataURI;
    }

    function setRevealURI(string memory baseBeforeRevealURI) external {
        require(msg.sender == owner );
        _baseBeforeRevealURI = baseBeforeRevealURI;
    }

    function reveal() external{
        require(msg.sender == owner );
        require(bytes(_baseURI()).length > 0, "baseURI is EMPTY");
        isRevealed = true;
    }

    function tokenURI(uint256 _tokenId) public view override(ERC721) returns (string memory){
        string memory baseURI;
        if(isRevealed){
            baseURI = _baseURI();
        }else{
            return _baseURIBeforeReveal();
        }
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(_tokenId))) : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable)
        returns (bool)
    {        
        return super.supportsInterface(interfaceId);
    }

    constructor() ERC721("MetaaniDNA" , "MDNA" ) {
        owner = msg.sender;
    } 

}