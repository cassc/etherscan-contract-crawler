// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC2981, ERC2981 } from "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./erc721a/ERC721AQueryable.sol";
import { OperatorFilterer } from "./OperatorFilterer.sol";

interface Suits {
  function burnXBatch(
    address from,
    uint256[] memory tokenIDs,
    uint256[] memory amounts
  ) external;
}

contract MVS1 is ERC721AQueryable, ERC2981, OperatorFilterer, Ownable {
  using Address for address;
  using Strings for uint256;

  string public _contractBaseURI = "https://mothvalley-stream.to.wtf/metadata/";
  string public _contractURI =
    "ipfs://bafkreib6bctopbul5jdyxwj7ypsh6i2puauf2qjgz3ofsm46hxgek6ghoa";

  bool public operatorFilteringEnabled;

  modifier notContract() {
    require(!_isContract(msg.sender), "contract not allowed");
    require(msg.sender == tx.origin, "proxy not allowed");
    _;
  }

  Suits private _suitsContract;

  event NewMint(uint256 tokenID, uint256 tokenA, uint256 tokenB);

  constructor() ERC721A("Moth Valley S1 Gallery", "MVS1") {
    _registerForOperatorFiltering();
    operatorFilteringEnabled = true;
    _setDefaultRoyalty(0x62C3c92B0154464C0c27BD8F7da06d0877229310, 900);
    _suitsContract = Suits(0x8aC698ED2CC84EAe503404443f8Df1feF818bd36);
  }

  function get(uint256 tokenA, uint256 tokenB) external {
    uint256[] memory tokenIDs = new uint256[](2);
    uint256[] memory amounts = new uint256[](2);
    tokenIDs[0] = tokenA;
    tokenIDs[1] = tokenB;
    amounts[0] = 1;
    amounts[1] = 1;

    _suitsContract.burnXBatch(msg.sender, tokenIDs, amounts);

    emit NewMint(_nextTokenId(), tokenA, tokenB);
    _mint(_msgSender(), 1);
  }

  /**
	@dev returns true if an NFT is minted
	*/
  function exists(uint256 _tokenId) external view returns (bool) {
    return _exists(_tokenId);
  }

  /**
	@dev tokenURI from ERC721 standard
	*/
  function tokenURI(
    uint256 _tokenId
  ) public view override(ERC721A, IERC721A) returns (string memory) {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    return
      string(abi.encodePacked(_contractBaseURI, _tokenId.toString(), ".json"));
  }

  /**
	@dev contractURI from ERC721 standard
	*/
  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  /**
   * ADMIN FUNCTIONS
   */
  // be careful setting this one
  function setImportantURIs(
    string memory newBaseURI,
    string memory newContractURI
  ) external onlyOwner {
    _contractBaseURI = newBaseURI;
    _contractURI = newContractURI;
  }

  //recover lost erc20. getting them back chance: very low
  function reclaimERC20Token(address erc20Token) external onlyOwner {
    IERC20(erc20Token).transfer(
      msg.sender,
      IERC20(erc20Token).balanceOf(address(this))
    );
  }

  function setSuitsContractAddress(address suitsContract) external onlyOwner {
    _suitsContract = Suits(suitsContract);
  }

  //recover lost nfts. getting them back chance: very low
  function reclaimERC721(address erc721Token, uint256 id) external onlyOwner {
    IERC721(erc721Token).safeTransferFrom(address(this), msg.sender, id);
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    _contractBaseURI = newBaseURI;
  }

  //anti-bot
  function _isContract(address _addr) private view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(_addr)
    }
    return size > 0;
  }

  //makes the starting token id to be 1
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function setApprovalForAll(
    address operator,
    bool approved
  ) public override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(
    address operator,
    uint256 tokenId
  )
    public
    payable
    override(IERC721A, ERC721A)
    onlyAllowedOperatorApproval(operator)
  {
    super.approve(operator, tokenId);
  }

  /**
   * @dev Both safeTransferFrom functions in ERC721A call this function
   * so we don't need to override them.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function setDefaultRoyalty(
    address receiver,
    uint96 feeNumerator
  ) public onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function setOperatorFilteringEnabled(bool value) public onlyOwner {
    operatorFilteringEnabled = value;
  }

  function _operatorFilteringEnabled() internal view override returns (bool) {
    return operatorFilteringEnabled;
  }

  function _isPriorityOperator(
    address operator
  ) internal pure override returns (bool) {
    // OpenSea Seaport Conduit:
    // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
    // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
    return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC721A, IERC721A, ERC2981) returns (bool) {
    // Supports the following `interfaceId`s:
    // - IERC165: 0x01ffc9a7
    // - IERC721: 0x80ac58cd
    // - IERC721Metadata: 0x5b5e139f
    // - IERC2981: 0x2a55205a
    return
      ERC721A.supportsInterface(interfaceId) ||
      ERC2981.supportsInterface(interfaceId);
  }
}