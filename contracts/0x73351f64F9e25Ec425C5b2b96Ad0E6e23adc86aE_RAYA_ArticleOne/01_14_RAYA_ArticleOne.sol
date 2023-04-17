pragma solidity ^0.8.13;
// SPDX-License-Identifier: MIT

/// @author: Bizinova, AaronChiu4
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/*                                                                                                                                                                                                                     
                                                            %@@@@%(  @@((((((@                      
                                          &@@/,,,  @@,,,.,,@@((((((#@@@#(((((@                      
                        /@@@@@@@@@@@@@@@*@@,,,,,&@@@@,,,,,,@@(((((((((@@(((((@                      
                      @@@@,,,,,,,,,,,,,,,,@,.,,,@@@@@%,,.,,@@(((((@((((((((((@                      
                     @@@@@,,,,,,,,,,,,,,,@@,,,,,@@@@@*,,,,,@@(((((@@&((((((((@                      
                     @@@@@,,,,,@@@@#*@@@@@@,,,,,.,,,,,,,.,*@@((((((@@@(((((((@                      
                     @@@@@,,,,,@@@@,,,,,,@@,,,,,.,,,,,,,,,@@@((((((@@@@@(((((@                      
                     @@@@@,,,,,@@@@@,,,,,,@@#,.,.,.,.,.#@@@@@@@@@@@@@@@@@@@@/         (@@  [email protected](((((@@
                     @@@@@,,,,,(@@@(,,,,#@@@@@@@@@@@@@   @@@@@@@@&  @@(((((((@* #@@(((((@#@@@(((((@@
                     @@@@@@@@@@&@@@@@@@@& @@@@@@@@&(,,@&@,,,,,,@ @((((((((((((((@@@(((((@@@@@(((((@@
                     @@@@@@@@#.........,    @@@@#,,,,,*@@,,,,,&@(((((((((((((((((@@(((((/@@@@(((((@@
         @@********    [email protected]@    @@@@@@,,,,,@,,,,@@@@(((((@@@@@@@(((((@@((((((@@@((((((@@
      @@@@*********  @@@[email protected]     @@@@@@@,,,,,,,@@@@%(((((@@@@@(((((((@@(((((((((((((((@ 
     @@@@**********%@@@@@....,@@@@@@@@@        @@@@@@&,,,,@ @@@@((((((((((((((((@@@@((((((((((((@@  
     @@@*****@@*****@@@@,@@@@@@@@@@[email protected]        @@@@,,,,,@ @@@@@(((((((((((((@ @@@@@@@&##&@@@@@    
    @@@%*****@@******@@@[email protected]        (@@@,,,,,,# @@@@@@@@@@@@@@@@    @@@@@@@@@@@@       
   @@@@***************@@[email protected]         @@@@@@@@@     @@@@@@@@@@@%*[email protected]                      
   @@@******@@@@*******@@@@@@@@@@@@@@           *@@@@@%(#&@@ @@[email protected]                      
  @@@/@@@@@@@@@@@@@@@@@@@@@@@@@@@@%###%    @@,,,.,,,,,,,,,,,,@@[email protected]                      
 #@@@@@@@@  @@@@@@*          @@@@@@@@@@@ @@@@,,,.,,,.,,,.,,,[email protected]@[email protected]@@@@@@@@                       
                           [email protected]@[email protected]@@@@,,,.,@@@@@@,,,@@@@[email protected]@@@@@@@&@                      
                           @@[email protected]@[email protected]@@@,,,.,,,,,#*.,@@@@@[email protected]                      
                          @@@[email protected]@[email protected]@@,,,.,(@@@@,,,,,,@@[email protected]                      
                         @@@[email protected]@,.,.,[email protected]@@@,.,.,[email protected]@....../%@@@@@@@                      
                        @@@[email protected]@@@[email protected],,,.*&@@@@@@@@@@@@@@@@@@@@@@@@*                        
                       &@@##%&@@@@@@@@@@@@@@@@@@@@ @@@@@@@@&@@@,                                    
                      ,@@@@@@@@# @@@@@@@@/                                                                                                                                                             

*/

contract RAYA_ArticleOne is ERC1155, Ownable, Pausable, ReentrancyGuard {
  /*
   * Public Variables
   */

  // Token name
  string public name = "Run As You Are - Article One";

  uint256 public totalSupplyMinted;

  string public tokenURI;

  bytes32 public OGClaimMerkleRoot;

  mapping(address => uint256) public addressToOGClaims;

  // event to emit when minting
  event MintEvent(uint256 timestamp, uint256 tokenId);

  constructor() ERC1155("") {
    totalSupplyMinted = 0;
    tokenURI = "ipfs://bafybeiaa3vmuhkgbkp7b3onhj2tz3iirkcpq2xejgkrcb2xvfrpvjyqg7i/";
  }

  /// @dev Set global URI, devs will send note/accompanying article if used
  /// @param newTokenURI New token URI string
  function setGlobalURI(string memory newTokenURI) public onlyOwner {
    tokenURI = newTokenURI;
  }

  /// @dev To return URI in OpenSea standard and for easy front-end retrieval
  /// @param _tokenId RAYA x Article One token Id to view
  function uri(uint256 _tokenId) public view override returns (string memory) {
    return string(abi.encodePacked(tokenURI, Strings.toString(_tokenId), ".json"));
  }

  /// @dev Owner minting function
  /// @notice For team to airdrop tokens
  /// @param accounts Array of accounts to mint to
  /// @param tokenIds Array of token Ids to mint per account
  /// @param tokenAmounts Array of token amounts to mint per account
  function adminMint(
    address[] calldata accounts,
    uint256[] calldata tokenIds,
    uint256[] calldata tokenAmounts
  ) public onlyOwner nonReentrant {
    uint256 sumTokens = 0;
    require(accounts.length == tokenAmounts.length, "accounts_ne_tokens_entered");

    for (uint256 i = 0; i < tokenAmounts.length; i++) {
      sumTokens += tokenAmounts[i];
    }

    for (uint256 i = 0; i < accounts.length; i++) {
      for (uint256 j = 0; j < tokenAmounts[i]; j++) {
        _mintTokenId(accounts[i], tokenIds[i]);
      }
    }
  }

  // Mint a token with set Id
  /// @dev Set Id determined by owner
  /// @param _to Address to mint token to
  // Mint a token with sequential id
  function _mintTokenId(address _to, uint256 _tokenId) private {
    _mint(_to, _tokenId, 1, "");
    totalSupplyMinted += 1;

    emit MintEvent(block.timestamp, _tokenId);
  }

  //batch burn
  /// @dev To burn multple tokens in a single transaction
  /// @param idArray Array of ids to burn
  function batchBurn(uint256[] calldata idArray, uint256[] calldata quan) public {
    super._burnBatch(msg.sender, idArray, quan);
  }

  // Required override from parent contract
  /// @dev Adds check that owner owns token
  /// @param id token id to burn
  function burn(uint256 id) public nonReentrant {
    super._burn(msg.sender, id, 1);
  }

  // When the contract is paused, all token transfers are prevented in case of emergency
  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override whenNotPaused {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  // Override ERC1155 such that zero amount token transfers are disallowed to prevent arbitrary creation of new tokens in the collection.
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public override {
    require(amount > 0, "AMOUNT_CANNOT_BE_ZERO");
    return super.safeTransferFrom(from, to, id, amount, data);
  }

  /// @dev To transfer multple tokens in a single transaction
  /// @param from Address transfering tokens from
  /// @param to Address transferring tokens to
  /// @param tokenIdArr Array of ids to transfer
  function batchTransfer(
    address from,
    address to,
    uint256[] calldata tokenIdArr,
    uint256[] calldata tokenAmountArr,
    bytes memory data
  ) public {
    for (uint256 i; i < tokenIdArr.length; i++) {
      safeTransferFrom(from, to, tokenIdArr[i], tokenAmountArr[i], data);
    }
  }

  /// @dev To pause contract - will allow transfers but no minting
  function pause() public onlyOwner {
    _pause();
  }

  /// @dev To pause contract - will allow transfers but no minting
  function unpause() public onlyOwner {
    _unpause();
  }

  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }

  /// @dev To withdraw funds to owner of the contract
  function withdraw() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }
}