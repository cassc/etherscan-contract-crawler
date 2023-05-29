// SPDX-License-Identifier: WTF

/*
 *  _          _        _         _           _          _               _             _
 * /\ \    _ / /\      /\ \      / /\        /\ \       / /\            _\ \          /\ \
 * \ \ \  /_/ / /      \ \ \    / /  \       \ \ \     / /  \          /\__ \        /  \ \
 *  \ \ \ \___\/       /\ \_\  / / /\ \__    /\ \_\   / / /\ \        / /_ \_\      / /\ \ \
 *  / / /  \ \ \      / /\/_/ / / /\ \___\  / /\/_/  / / /\ \ \      / / /\/_/     / / /\ \_\
 *  \ \ \   \_\ \    / / /    \ \ \ \/___/ / / /    / / /\ \_\ \    / / /         / /_/_ \/_/
 *   \ \ \  / / /   / / /      \ \ \      / / /    / / /\ \ \___\  / / /         / /____/\
 *    \ \ \/ / /   / / /   _    \ \ \    / / /    / / /  \ \ \__/ / / / ____    / /\____\/
 *     \ \ \/ /___/ / /__ /_/\__/ / /___/ / /__  / / /____\_\ \  / /_/_/ ___/\ / / /______
 *      \ \  //\__\/_/___\\ \/___/ //\__\/_/___\/ / /__________\/_______/\__\// / /_______\
 *       \_\/ \/_________/ \_____\/ \/_________/\/_____________/\_______\/    \/__________/
 *          _          _            _          _            _             _            _
 *         /\ \       /\ \         /\ \       /\ \         /\ \     _    /\ \         / /\
 *        /  \ \     /  \ \        \ \ \     /  \ \       /  \ \   /\_\ /  \ \____   / /  \
 *       / /\ \ \   / /\ \ \       /\ \_\   / /\ \ \     / /\ \ \_/ / // /\ \_____\ / / /\ \__
 *      / / /\ \_\ / / /\ \_\     / /\/_/  / / /\ \_\   / / /\ \___/ // / /\/___  // / /\ \___\
 *     / /_/_ \/_// / /_/ / /    / / /    / /_/_ \/_/  / / /  \/____// / /   / / / \ \ \ \/___/
 *    / /____/\  / / /__\/ /    / / /    / /____/\    / / /    / / // / /   / / /   \ \ \
 *   / /\____\/ / / /_____/    / / /    / /\____\/   / / /    / / // / /   / / /_    \ \ \
 *  / / /      / / /\ \ \  ___/ / /__  / / /______  / / /    / / / \ \ \__/ / //_/\__/ / /
 * / / /      / / /  \ \ \/\__\/_/___\/ / /_______\/ / /    / / /   \ \___\/ / \ \/___/ /
 * \/_/       \/_/    \_\/\/_________/\/__________/\/_/     \/_/     \/_____/   \_____\/
 *          _              _            _             _           _           _         _
 *         /\ \           /\ \         /\ \     _    /\ \        / /\        /\ \      / /\
 *        /  \ \         /  \ \       /  \ \   /\_\ /  \ \      / /  \       \ \ \    / /  \
 *       / /\ \_\       / /\ \ \     / /\ \ \_/ / // /\ \ \    / / /\ \__    /\ \_\  / / /\ \__
 *      / / /\/_/      / / /\ \_\   / / /\ \___/ // / /\ \_\  / / /\ \___\  / /\/_/ / / /\ \___\
 *     / / / ______   / /_/_ \/_/  / / /  \/____// /_/_ \/_/  \ \ \ \/___/ / / /    \ \ \ \/___/
 *    / / / /\_____\ / /____/\    / / /    / / // /____/\      \ \ \      / / /      \ \ \
 *   / / /  \/____ // /\____\/   / / /    / / // /\____\/  _    \ \ \    / / /   _    \ \ \
 *  / / /_____/ / // / /______  / / /    / / // / /______ /_/\__/ / /___/ / /__ /_/\__/ / /
 * / / /______\/ // / /_______\/ / /    / / // / /_______\\ \/___/ //\__\/_/___\\ \/___/ /
 * \/___________/ \/__________/\/_/     \/_/ \/__________/ \_____\/ \/_________/ \_____\/
 *
 */

pragma solidity ^0.8.15;

import '@openzeppelin/contracts/access/ownable.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import 'erc721a/contracts/ERC721A.sol';

interface NFT {
  function make(address to) external;
}

contract VisibleFriendsGenesis is Ownable, ERC2981, ERC721A {
  /*
   * constant
   */

  string public baseURI = '';

  address public makeContractAddress = address(0);

  uint256 public immutable price = 0.005 ether;

  uint256 public immutable maxSupply = 2022;

  uint256 public immutable maxWalletSupply = 22;

  uint256 public immutable maxWalletFreeSupply = 2;

  /*
   * override
   */

  constructor() ERC721A('VisibleFriendsGenesis', 'VFG') {}

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC2981, ERC721A)
    returns (bool)
  {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  /*
   * expose
   */

  function nextTokenId() external view returns (uint256) {
    return _nextTokenId();
  }

  function numberMinted(address owner) external view returns (uint256) {
    return _numberMinted(owner);
  }

  /*
   * mint & burn
   */

  function mint(address to, uint256 quantity) external payable {
    unchecked {
      uint256 currentSupply = _nextTokenId() - 1;
      require((currentSupply + quantity) <= maxSupply, 'E0');

      uint256 walletSupply = _numberMinted(msg.sender);
      require((walletSupply + quantity) <= maxWalletSupply, 'E1');

      uint256 walletFreeSupply = walletSupply > maxWalletFreeSupply
        ? maxWalletFreeSupply
        : walletSupply;
      uint256 freeQuantity = maxWalletFreeSupply > walletFreeSupply
        ? maxWalletFreeSupply - walletFreeSupply
        : 0;
      require(msg.value >= price * (quantity > freeQuantity ? quantity - freeQuantity : 0), 'E2');
    }

    _mint(to, quantity);
  }

  function burn(uint256 tokenId) external {
    require(ownerOf(tokenId) == msg.sender, 'E3');
    _burn(tokenId);

    if (makeContractAddress != address(0)) {
      NFT makeContract = NFT(makeContractAddress);
      makeContract.make(msg.sender);
    }
  }

  /*
   * admin
   */

  function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function setBaseURI(string calldata uri) external onlyOwner {
    baseURI = uri;
  }

  function setMakeContract(address make) external onlyOwner {
    makeContractAddress = make;
  }

  function withdraw(address to) external onlyOwner {
    payable(to).transfer(address(this).balance);
  }
}