// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

contract NFTContract is ERC1155, Ownable {

  string public name = "Appreciation Collection";
  string public description = "A collection to appreciate people who helped you out in any way.";
  address manager;
  string ipfsuri;
  uint128 private _startMintFeeWei = 5e15;

  event Mint(address indexed minter, uint256 tokenId);

  constructor(address _mananger) ERC1155("ipfs://QmebFkUcKXD3hertJVjiDUJcHwh2Et1kNTUNRTVBXKMh9j/{id}.json") {
    manager = _mananger;
    ipfsuri = "ipfs://QmebFkUcKXD3hertJVjiDUJcHwh2Et1kNTUNRTVBXKMh9j/";
  }

  function uri(uint256 _tokenId) override public view returns (string memory) {
    return string(
      abi.encodePacked(
          ipfsuri,
          Strings.toString(_tokenId),
          ".json"
      )
    );
  }

  function setURI(string memory _uri) public onlyManager {
    _setURI(_uri);
  }

  function setIPFS(string memory _ipfs) public onlyManager {
    ipfsuri = _ipfs;
  }

  function mint(address mintTo, uint256 tokenId) payable public  {
    require(msg.value >= _startMintFeeWei);
    require(msg.sender != mintTo);
    _mint(mintTo, tokenId, 1, "");
    emit Mint(mintTo, tokenId);
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) pure override internal {
    require(from == address(0) || to == address(0), "This a Soulbound token. It cannot be transferred. It can only be burned by the token owner.");
  }

  function burn(uint256 tokenId, uint256 amount) external {
    require(balanceOf(msg.sender, tokenId) >= amount, "not enough tokens to burn");
    _burn(msg.sender, tokenId, amount);
  }

  function _burn(address sender, uint256 tokenId, uint256 amount) internal override (ERC1155) {
    super._burn(sender, tokenId, amount);
  }

  modifier onlyManager() {
    _checkManager();
    _;
  }

  function _checkManager() internal view virtual {
    require(manager == msg.sender, "NFTContract: caller is not the owner");
  }

  function payManager() external {
    require(msg.sender == manager, "NFTContract: forbidden");
    payable(manager).transfer(address(this).balance);
  }
}