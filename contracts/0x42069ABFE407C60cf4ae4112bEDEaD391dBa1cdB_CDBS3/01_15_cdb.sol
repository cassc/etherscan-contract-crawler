/*

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        ,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@                ,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@                     ,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@           @@@@@@@,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@   @@@     @@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@   @@@@@   @@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@.  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@   @@@@@                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@                        @@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@              @@   @@.  @@@@@@@@@@@@@@@@@@@     @@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@,,,           @@   @@.  @@@[email protected]@@@@...  @@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@,,,           @@   @@.  @@@        @@@@@     @@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@,,,           @@   @@.       @@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@,,,        @@@       @@@     ,,,,,,,,@@@     @@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,     @@@@@   @@@@@                @@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,        @@@@@@@.               ,,,@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,                             ,,,@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,             ,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

                                CryptoDickbutts Series 3
*/

pragma solidity ^0.6.12;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract CDBS3 is ERC721, Ownable {
    using SafeMath for uint256;
    uint256 public constant maxTokens = 5200;
    uint256 public constant maxMintsPerTx = 30;
    uint256 public constant startingId = 160;
    uint256 public nextTokenId = startingId; //legacy collection ended at token #159 but also included #5000. Token #5000 will be skipped.
    uint256 tokenPrice = 52000000000000000; //0.052 ether
    uint256 discountPrice = 46800000000000000; //0.0468 ether (10% off)
    string private _contractURI;
    address[] public partnerProjects; //store partner project tokens so that holders may claim a discount
    mapping(address => bool) public hasClaimedDiscount; //records whether a wallet has claimed a discount
    string public provenance;
    bool public metaDataFrozen = false;
    bool public liveSale = false;
    address payable public teamMember; //dev team member
    address private deployer;

    constructor(address payable _teamMember)
        public
        ERC721("CryptoDickbutts S3", "CDB")
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

    //Discount minting for holders of partner projects
    function mintWithPartnerDiscount(uint256 quantity)
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
            msg.value == discountPrice.mul(quantity),
            "Wrong amount of ether sent!"
        );

        require(
            holdsPartnerProject(msg.sender),
            "You don't own a token from one of our partners"
        );
        require(
            !hasAddressClaimedDiscount(msg.sender),
            "Sorry, one discount mint per address!"
        );
        setDiscountClaimed(msg.sender);

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
            if (nextTokenId == 5000) {
                nextTokenId++; //skip 5000
            }
        }
    }

    //Allow owner to enable/disable the sale.
    function toggleSale() 
        public 
        onlyTeam 
    {
        liveSale = !liveSale;
    }

    //Team member can change their wallet
    function setTeamMember(address payable newAddress) 
        public 
    {
        require(msg.sender == teamMember);
        teamMember = newAddress;
    }

    //Keep track of who has claimed a discount mint
    function setDiscountClaimed(address _claimant) 
        internal 
    {
        hasClaimedDiscount[_claimant] = true;
    }

    function hasAddressClaimedDiscount(address _claimant)
        public
        view
        returns (bool)
    {
        return hasClaimedDiscount[_claimant];
    }

    //Allow discounts for holders of certain partner projects
    function setPartnerProjects(address _partnerToken) 
        external 
        onlyTeam 
    {
        partnerProjects.push(_partnerToken);
    }

    function holdsPartnerProject(address _claimant) 
        public 
        view 
        returns (bool) 
    {
        for (uint256 i = 0; i < partnerProjects.length; i++) {
            if (IERC721(partnerProjects[i]).balanceOf(_claimant) > 0) {
                return true;
            }
        }
        return false;
    }

    function addressEligibleForDiscount(address _claimant)
        public
        view
        returns (bool)
    {
        if (
            !hasAddressClaimedDiscount(_claimant) &&
            holdsPartnerProject(_claimant)
        ) {
            return true;
        } else {
            return false;
        }
    }

    //Withdraw eth from the contract and send to team members
    function withdraw() 
        public 
        onlyTeam 
    {
        payable(teamMember).send(address(this).balance.div(10)); //send 10% to team member
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