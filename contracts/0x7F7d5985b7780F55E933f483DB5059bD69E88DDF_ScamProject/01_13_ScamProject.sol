/***************************************************************************************** 
  ______  ____  _____     _____      ______  _______   ____      |__|  ____    ____  _/  |_ 
 /  ___/_/ ___\ \__  \   /     \     \____ \ \_  __ \ /  _ \     |  |_/ __ \ _/ ___\ \   __\
 \___ \ \  \___  / __ \_|  Y Y  \    |  |_> > |  | \/(  <_> )    |  |\  ___/ \  \___  |  |  
/____  > \___  >(____  /|__|_|  /    |   __/  |__|    \____/ /\__|  | \___  > \___  > |__|  
     \/      \/      \/       \/     |__|                    \______|     \/      \/        

*****************************************************************************************/

// SPDX-License-Identifier: None
pragma solidity ^0.8.8;

import "./Ownable.sol";
import "./Address.sol";
import "./ERC721.sol";
import "./ERC2981.sol";

error SaleDeactivated();

contract ScamProject is Ownable, ERC721, ERC2981 {
  using Address for address;

  // EVENTS ****************************************************
    event URISet(string regularURI, string diamondURI);

  // MEMBERS ****************************************************

  uint256 public immutable MAX_SUPPLY = 5000;
  uint256 public immutable DIAMOND_PASS_SUPPLY = 500;
  uint256 public immutable REGULAR_PASS_SUPPLY = 4500;

  // Number of currently supplied tokens
  uint256 public regularPassSupply = 0;
  uint256 public diamondSupply = 0;
  uint256 public totalSupply = 0;

  // Price for diamond Pass
  uint256 diamondPrice = 0.05 ether;

  bool public saleOpen;

  string public regularURI;
  string public diamondURI;

  // 1 = regular, 2 = diamond
  mapping (uint256 => uint256) private edition;
  mapping (address => uint256) public diamondPassMintBalanceOf;
  mapping (address => uint256) public regularPassMintBalanceOf;

  address public royaltyRegistry;

  // CONSTRUCTOR ***************************************************

  constructor( address _royaltyRegistry )
  ERC721("Scam Project", "SCAM")
  {
    // mints 100 diamond passes to owner for future collaborations and giveaways
    mintPremiumGiveaway(100);
    royaltyRegistry = _royaltyRegistry;
    _setRoyalties(_royaltyRegistry, 700); // 7%
  }

  // PUBLIC METHODS ****************************************************
 
  /// @notice Allows users to buy regular pass during public sale
  /// @dev Preventing contract buys has some downsides, but it seems to be what the NFT market generally wants as a bot mitigation measure
  /// @param numberOfTokens the number of NFTs to buy
  function buyFree(uint256 numberOfTokens) external {

    if(!saleOpen) revert SaleDeactivated();

    require(regularPassMintBalanceOf[msg.sender] + numberOfTokens < 6, "Exceeds regular pass mint limit of 5, per wallet");
    require(numberOfTokens > 0, "Should mint atleast 1 regular pass");
    require(regularPassSupply + numberOfTokens <= REGULAR_PASS_SUPPLY, "Regular pass supply maxed out");

    // disallow contracts from buying
    require(
      (!msg.sender.isContract() && msg.sender == tx.origin),
      "Contract buys not allowed"
    );

    regularPassMintBalanceOf[msg.sender] += numberOfTokens;

    // Set edition to regular pass, gas saving approach by setting the first token edition only
    edition[totalSupply+1] = 1;
    regularPassSupply += numberOfTokens;

    mint(msg.sender, numberOfTokens);
  }

  /// @notice Allows users to buy with fees of diamondPrice
  /// @dev Preventing contract buys has some downsides, but it seems to be what the NFT market generally wants as a bot mitigation measure
  function buyPremium() external payable {

    if(!saleOpen) revert SaleDeactivated();

    require(diamondPassMintBalanceOf[msg.sender] + 1 < 2, "Only 1 diamond pass per wallet");
    require(diamondSupply + 1 <= DIAMOND_PASS_SUPPLY, "Diamond pass supply maxed out");

    // disallow contracts from buying
    require(
      (!msg.sender.isContract() && msg.sender == tx.origin),
      "Contract buys not allowed"
    );

    require(msg.value >= diamondPrice, "Insufficient payment");

    // refund if user paid more than the cost to mint
    if (msg.value > diamondPrice) {
      Address.sendValue(payable(msg.sender), msg.value - diamondPrice);
    }

    diamondPassMintBalanceOf[msg.sender] += 1;
    diamondSupply += 1;

    // Set edition to diamond pass
    edition[totalSupply+1] = 2;

    mint(msg.sender, 1);
  }

  /// @inheritdoc ERC165
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC2981)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function getEdition(uint256 tokenId) public view returns(uint256 _edition){
    if(tokenId > totalSupply) revert("Non-existent token");

    uint256 curr = tokenId;
    while(true){
      if(edition[curr] == 0) curr--;
      else{  return edition[curr]; }
    }
  }

  /**
  @param tokenId : The token id
  Returns the uri based on the edition => Regular pass or Diamond pass
  */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    return (getEdition(tokenId) == 1) ? regularURI : diamondURI;
  }

  // OWNER METHODS *********************************************************

  function mintPremiumGiveaway(uint256 numberOfTokens) internal {

    diamondPassMintBalanceOf[msg.sender] += numberOfTokens;
    diamondSupply += numberOfTokens;

    // only need to set for first index, for gas saving
    edition[totalSupply+1] = 2;

    mint(msg.sender, numberOfTokens);
  }

  function setSaleActivation(bool _activation) external onlyOwner{
    saleOpen = _activation;
  }

  function setURIs(string memory _regularURI, string memory _diamondURI) external onlyOwner{
    regularURI = _regularURI;
    diamondURI = _diamondURI;
    emit URISet(_regularURI, _diamondURI);
  }

  // PRIVATE/INTERNAL METHODS ****************************************************

  function mint(address to, uint256 numberOfTokens) private {
    _safeMint(to, numberOfTokens);
    totalSupply += numberOfTokens;
  }
}