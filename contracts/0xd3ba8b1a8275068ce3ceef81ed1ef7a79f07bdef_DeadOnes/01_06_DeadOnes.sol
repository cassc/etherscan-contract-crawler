// SPDX-License-Identifier: MIT

//     _ .-') _     ('-.   ('-.     _ .-') _
//    ( (  OO) )  _(  OO) ( OO ).-.( (  OO) )
//     \     .'_ (,------./ . --. / \     .'_
//     ,`'--..._) |  .---'| \-.  \  ,`'--..._)
//     |  |  \  ' |  |  .-'-'  |  | |  |  \  '
//     |  |   ' |(|  '--.\| |_.'  | |  |   ' |
//     |  |   / : |  .--' |  .-.  | |  |   / :
//     |  '--'  / |  `---.|  | |  | |  '--'  /
//     `-------'  `------'`--' `--' `-------'
//                      .-') _   ('-.    .-')
//                     ( OO ) )_(  OO)  ( OO ).
//     .-'),-----. ,--./ ,--,'(,------.(_)---\_)
//    ( OO'  .-.  '|   \ |  |\ |  .---'/    _ |
//    /   |  | |  ||    \|  | )|  |    \  :` `.
//    \_) |  |\|  ||  .     |/(|  '--.  '..`''.)
//      \ |  | |  ||  |\    |  |  .--' .-._)   \
//       `'  '-'  '|  | \   |  |  `---.\       /
//         `-----' `--'  `--'  `------' `-----'

pragma solidity ^0.8.11;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

error LogicError(string message);

contract DeadOnes is ERC721A, Ownable {
  using StringsUpgradeable for uint256;

  uint256 public constant TEAM_SUPPLY = 100;
  uint256 public USED_TEAM_SUPPLY = 0;
  bool public IS_REVEALED = false;
  string public TOKEN_BASE_URL = "ipfs://tba";
  string public TOKEN_URL_SUFFIX = ".json";
  string public NOT_REVEALED_URL =
    "ipfs://QmadFrk1mCULVkTZk1eqW9QR7dKcBzoFdHnk7Rx8eVdSGK";
  address public WITHDRAW_ADDRESS = 0xdf058F9915ADf447695eE01cb6F0A896D4C0b7a6;
  address public SURVIVED_CONTRACT;

  constructor() ERC721A("DeadOnes", "DONE") {}

  modifier onlyAuthorized() {
    // disallow access from contracts
    if (
      msg.sender == SURVIVED_CONTRACT ||
      tx.origin == SURVIVED_CONTRACT ||
      msg.sender == owner()
    ) {
      _;
    } else {
      revert LogicError("Only authorized address can call this function");
    }
  }

  function killSperm(address to, uint256 count) external onlyAuthorized {
    _safeMint(to, count);
  }

  function gangBang(uint256 _count) external onlyOwner {
    if (USED_TEAM_SUPPLY + _count > TEAM_SUPPLY) {
      revert LogicError("team_supply_exceeded");
    }
    USED_TEAM_SUPPLY += _count;
    _safeMint(msg.sender, _count);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return TOKEN_BASE_URL;
  }

  function _suffix() internal view virtual returns (string memory) {
    return TOKEN_URL_SUFFIX;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
    if (!IS_REVEALED) {
      return NOT_REVEALED_URL;
    }
    string memory baseURI = _baseURI();
    string memory suffix = _suffix();
    return
      bytes(baseURI).length != 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(), suffix))
        : "";
  }

  // - management only functions
  function setSurvivedContract(address _survivedContract) external onlyOwner {
    SURVIVED_CONTRACT = _survivedContract;
  }

  function setTokenBaseUrl(string memory _tokenBaseUrl) public onlyOwner {
    TOKEN_BASE_URL = _tokenBaseUrl;
  }

  function setTokenSuffix(string memory _tokenUrlSuffix) public onlyOwner {
    TOKEN_URL_SUFFIX = _tokenUrlSuffix;
  }

  function setIsRevealed(bool status) public onlyOwner {
    IS_REVEALED = status;
  }

  function setWithdrawAddress(address _withdrawAddress) public onlyOwner {
    WITHDRAW_ADDRESS = _withdrawAddress;
  }

  function withdrawAll() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0);

    _withdraw(WITHDRAW_ADDRESS, address(this).balance);
  }

  function setNotRevealedUrl(string memory _notRevealedUrl) public onlyOwner {
    NOT_REVEALED_URL = _notRevealedUrl;
  }

  function _withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{value: _amount}("");
    require(success, "Transfer failed.");
  }
}