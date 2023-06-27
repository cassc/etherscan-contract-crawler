pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "erc721a/contracts/ERC721A.sol";
import "./OrangApes.sol";

contract PsyopOrangApesMinter is Ownable, AccessControl {
  using SafeMath for uint256;

  OrangApes private _orangApesContract;
  ERC20 private _psyopContract;

  bool public isMintingActive = false;

  uint256 public _pysopPrice = 17500 ether; // ether keyword is just *10^18

  constructor(
    address payable _orangApesContractAddress,
    address psyopContractAddress
  ) {
    _orangApesContract = OrangApes(_orangApesContractAddress);
    _psyopContract = ERC20(psyopContractAddress);
  }

  function mintWithPsyop(uint _count) public {
    require(
      isMintingActive && _orangApesContract.isMintingActive(),
      "PsyopOrangApesMinter: Minting not active"
    );
    require(
      _count > 0 && _count <= _orangApesContract.MAX_PER_MINT(),
      "PsyopOrangApesMinter: Minting too many"
    );
    require(
      _psyopContract.balanceOf(msg.sender) >= _pysopPrice.mul(_count),
      "PsyopOrangApesMinter: Not enough PSYOP"
    );
    require(
      _psyopContract.allowance(msg.sender, address(this)) >=
        _pysopPrice.mul(_count),
      "PsyopOrangApesMinter: Not enough PSYOP approved"
    );

    _psyopContract.transferFrom(
      msg.sender,
      address(this),
      _pysopPrice.mul(_count)
    );

    _orangApesContract.reserveNFTs(_count, msg.sender);
  }

  function withdrawPsyop(address _to, uint256 _amount) public onlyOwner {
    _psyopContract.transfer(_to, _amount);
  }

  function setPsyopPrice(uint256 _newPrice) public onlyOwner {
    _pysopPrice = _newPrice;
  }

  function toggleMinting() public onlyOwner {
    isMintingActive = !isMintingActive;
  }
}