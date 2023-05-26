/* credit to CDBS3 */

pragma solidity ^0.6.12;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; //minor custom edits
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract LEMURLEMUR is ERC721, Ownable {
    using SafeMath for uint256;
    uint256 public constant maxTokens = 3030;
    uint256 public constant maxMintsPerTx = 10;
    uint256 public constant startingId = 0;
    uint256 public nextTokenId = startingId; 
    uint256 tokenPrice = 50000000000000000; //0.050 ether
    string private _contractURI;
    string public provenance;
    bool public metaDataFrozen = false;
    bool public liveSale = false;
    address payable public teamMember; //dev team member
    address private deployer;

    constructor(address payable _teamMember)
        public
        ERC721("LEMUR LEMUR", "LMR")
    {
        teamMember = _teamMember; 
        deployer = msg.sender;
    }

    modifier duringSale() {
        require(
            liveSale,
             "Sale is not live!"
             );
        _;
    }

    //authenticate team wallets for certain tasks
    modifier onlyTeam() {
        require(
            msg.sender == deployer ||
                msg.sender == teamMember ||
                msg.sender == owner(),
            "Not authorized!"
        );
        _;
    }

    modifier notFrozen() {
        require(
            !metaDataFrozen,
            "Metadata URI is permanently frozen"
            );
        _;
    }

    //Set base URI path for each group of tokens
    //This is a modification to the standard EC721 method that permits dev to load metadata into the contract on a partial basis
    //See ERC721.sol
    function setMetadataURI(uint256 group, string calldata _metadataURI)
        external
        onlyTeam
        notFrozen
    {
        _setMetadataURI(group, _metadataURI);
    }

    //set initial metadata URI
    function setInitialMetadataURI(string calldata _initialMetadataURI)
        external
        onlyTeam
        notFrozen
    {
        _setInitialMetadataURI(_initialMetadataURI);
    }

    //Project-level URI
    function setContractURI(string memory contractURI_) 
        external 
        onlyTeam 
    {
        _contractURI = contractURI_;
    }

    function contractURI() 
        public 
        view 
        returns (string memory) 
    {
        return _contractURI;
    }

    //Allows Owner to freeze token metadata URI permanently. Project-level URI is not frozen in case links need to be upated. 
     function freezeMetadata() 
        public 
        onlyOwner
    {
        metaDataFrozen=true;
    }   

    //Provenance may only be set once irreversibly
    //Provenance is a string that should be an IPFS CID or file hash
    function setProvenance(string memory _provenance) 
        external 
        onlyOwner 
    {
        require(
            bytes(provenance).length == 0,
             "Provenance already set!"
             );
        provenance = _provenance;
    }

    //Minting
    function mint(uint256 quantity) 
        external 
        payable 
        duringSale 
    {
        require(
            quantity <= maxMintsPerTx,
            "There is a limit on minting too many at a time!"
        );
        require(
            totalSupply().add(quantity) <= maxTokens,
            "Minting this many would exceed supply!"
        );
        require(
            msg.value == tokenPrice.mul(quantity),
            "Wrong amount of ether sent!"
        );

        minter(msg.sender, quantity);
    }

    

    //Dev bulk minting in order to distribute mints to legacy holders and dev team.
    function devMint(
        address payable[] memory recipients,
        uint256[] memory quantity
    ) 
        external 
        onlyOwner 
    {
        //ensure data integrity
        require(recipients.length == quantity.length, "Data length mismatch!");
        //ensure dev mint would not exceed the cap
        uint256 totalMintRequested = 0;
        for (uint256 i = 0; i < quantity.length; i++) {
            totalMintRequested = totalMintRequested.add(quantity[i]);
        }
        require(
            totalSupply().add(totalMintRequested) <= maxTokens,
            "Minting this many would exceed supply!"
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            minter(recipients[i], quantity[i]);
        }
    }

    //mint
    function minter(address payable sender, uint256 quantity) 
        internal 
    {
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(sender, nextTokenId);
            nextTokenId++;
        }
    }

    //Allow owner to enable/disable the sale.
    function toggleSale() 
        public 
        onlyTeam 
    {
        liveSale = !liveSale;
    }

    //Withdraw eth from the contract and send to team members
    function withdraw() 
        public 
        onlyTeam 
    {
        payable(owner()).send(address(this).balance); //send balance to owner
    }

    //Allow token burn after sale is complete
    function burn(uint256 tokenId) 
        public 
        virtual 
    {
        require(
            !liveSale,
             "No burning while the sale is open"
             );
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    receive () external payable {}
}