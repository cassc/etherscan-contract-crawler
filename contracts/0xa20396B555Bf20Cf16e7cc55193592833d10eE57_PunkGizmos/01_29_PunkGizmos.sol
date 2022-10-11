// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721Tradeable.sol";

contract PunkGizmos is Context, ERC721Tradeable {
  using SafeMath for uint256;
  using SafeMath for int256;
  using Counters for Counters.Counter;
  uint256 mintStage = 0;
  // this map holds the who staked what
  mapping (uint256 => StakingEvent) stakedTokens;
  // this map holds the gizmos weights that are used during payment
  // heavy gizmos have a higher share of the payment
  mapping (uint256 => uint256) gizmoToWeights;
  uint256 rarityScale = 100000000000;
  uint256[] staked;
  uint256 lastCalculationEpoch;
  mapping(address => uint256[]) stakeHolders;

  struct StakingEvent {
    uint256 epochOfStake;
    uint256 weiDue;
    uint256 epochOfCalculation;
    address holder;
    uint256 y;
  }

  constructor(address _proxyRegistryAddress) ERC721Tradeable("PunkGizmos", "PUNKG", _proxyRegistryAddress) {
    _baseTokenURI = "ipfs://tbd/";
  }

    function publicMint(
        uint256 amount
    ) public virtual payable {
        require(mintStage == 2, "Public mint not started");
        _mintValidate(amount, _msgSender(), false);
        _safeMintTo(_msgSender(), amount);
    }

    function setGizmosToWeights(uint256[] memory gizmos, uint256[] memory weights) public onlyOwner {
      require(gizmos.length == weights.length, "Gizmos and weights must be the same length");
      for (uint256 i = 0; i < gizmos.length; i++) {
        gizmoToWeights[gizmos[i]] = weights[i];
      }
    }

    function allowlistMint(
        bytes32[] calldata _merkleProof,
        uint256 amount
    ) public virtual payable {
        require(isWhitelisted(_merkleProof), "Not a part of Whitelist");

        _mintValidate(amount, _msgSender(), true);
        _safeMintTo(_msgSender(), amount);
    }

    function teamMint(
        uint256 amount,
        address to
    ) public virtual onlyOwner {
        _safeMintTo(to, amount);
    }

    function setBaseTokenURI(string memory uri) public onlyOwner {
      _baseTokenURI = uri;
    }

    // this function just wraps the stakeGizmo function
    function stakeManyGizmos(uint256[] memory gizmoIds) public {
      for (uint256 i = 0; i < gizmoIds.length; i++) {
        stakeGizmo(gizmoIds[i]);
      }
    }

    // this function just wraps the unstakeGizmo function
    function unstakeManyGizmos(uint256[] memory gizmoIds) public {
      for (uint256 i = 0; i < gizmoIds.length; i++) {
        unstakeGizmo(gizmoIds[i]);
      }
    }

    // use this function to stake your gizmo and earn royalties of sales after the event
    function stakeGizmo(uint256 gizmo) public {
      // mint stage 3 means the mint phase is over
      require(mintStage == 3, "Mint not finished");
      require(_msgSender() == ownerOf(gizmo), "Not owner of token");
      require(stakedTokens[gizmo].epochOfStake == 0, "Already staked");
      _burn(gizmo);
      StakingEvent memory sevent = StakingEvent(block.number, 1, 0, _msgSender(), 0);
      stakedTokens[gizmo] = sevent;
      stakeHolders[_msgSender()].push(gizmo);
    }

    // use this function to regain full ownership of your gizmo and stop earning royalties
    function unstakeGizmo(uint256 gizmo) public {
      // mint stage 3 means the mint phase is over
      require(mintStage == 3, "Mint not finished");
      require(stakedTokens[gizmo].epochOfStake != 0, "Already unstaked");
      require(_msgSender() == stakedTokens[gizmo].holder, "Not owner of token");
      _remintTo(_msgSender(), gizmo);
      delete stakedTokens[gizmo];
      for (uint256 i; i < stakeHolders[_msgSender()].length; i++) {
        if (stakeHolders[_msgSender()][i] == gizmo) {
          stakeHolders[_msgSender()][i] = stakeHolders[_msgSender()][stakeHolders[_msgSender()].length - 1];
          stakeHolders[_msgSender()].pop();
          break;
        }
      }
    }

    // this function needs to be called at least once before the royalties can be claimed
    function calculateRewards() public {
      // mint stage 3 means the mint phase is over
      require(mintStage == 3, "Mint not finished");
      uint256 currentEpoch = block.number;
      // there should be an interval of at least 24h between calls
      require(block.number > lastCalculationEpoch + 72, "Too early, need to wait at least 72 blocks since last calculation");
      // sum all time differences
      uint256 sumEpochs = 0;
      for (uint256 i = 0; i < staked.length; i++) {
        uint256 y = ((currentEpoch - stakedTokens[staked[i]].epochOfStake).mul(gizmoToWeights[staked[i]])).div(rarityScale);
        sumEpochs = sumEpochs + y;
        stakedTokens[staked[i]].y = y;
      }
      uint256 currentContractBalance = address(this).balance;
      // calculate the reward for each gizmo
      for (uint256 i = 0; i < staked.length; i++) {
        StakingEvent memory gizmo = stakedTokens[staked[i]];
        uint256 bps = gizmo.y.div(sumEpochs).mul(10000);
        gizmo.weiDue = gizmo.weiDue.add(currentContractBalance.mul(bps).div(10000));
        gizmo.epochOfCalculation = currentEpoch;
      }
      lastCalculationEpoch = currentEpoch;
    }

    function mintTo(address _to) public onlyOwner {
        _mintValidate(1, _to, false);
        _safeMintTo(_to, 1);
    }

    function _remintTo(address _to, uint256 _tokenId) internal virtual {
      _mint(_to, _tokenId);
    }
    
    function _safeMintTo(
        address to,
        uint256 amount
    ) internal {
      uint256 startTokenId = _nextTokenId.current();
      require(SafeMath.sub(startTokenId, 1) + amount <= MAX_SUPPLY, "collection sold out");
      require(to != address(0), "cannot mint to the zero address");
      
      _beforeTokenTransfers(address(0), to, startTokenId, amount);
        for(uint256 i; i < amount; i++) {
          uint256 tokenId = _nextTokenId.current();
          _nextTokenId.increment();
          _mint(to, tokenId);
        }
      _afterTokenTransfers(address(0), to, startTokenId, amount);
    }

    function _mintValidate(uint256 amount, address to, bool isAllowlist) internal virtual {
      require(amount != 0, "cannot mint 0");
      require(isSaleActive() == true, "sale non-active");
      uint256 balance = balanceOf(to);
      if (balance + amount >= maxFree()) {
        int256 free = int256(maxFree()) - int256(balance);
        if(isAllowlist && free > 0) {
          require(int256(msg.value) >= (int256(amount) - free) * int256(mintPriceInWei()), "incorrect value sent");
        } else {
          require(msg.value >= SafeMath.mul(amount, mintPriceInWei()), "incorrect value sent");
        }
      }
      require(amount <= maxMintPerTx(), "quantity is invalid, max reached on tx");
      require(balance + amount <= maxMintPerWallet(), "quantity is invalid, max reached on wallet");
    }

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    function setPublicSale(bool toggle) public virtual onlyOwner {
        _isActive = toggle;
    }

    function setMintStage(uint256 stage) public virtual onlyOwner {
        mintStage = stage;
    }

    function isSaleActive() public view returns (bool) {
        return _isActive;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Tradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override(IERC721, ERC721)
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function contractURI() public pure returns (string memory) {
      return "ipfs://bafkreih6qkuo5bmhndbnav7qwlmktzdjmge6h7mknv7qog3s7wf6kix3fe";
    }

    function claimRoyalties() public {
      require(stakeHolders[_msgSender()].length > 0, "No staked tokens");
      uint256 due = 0;
      for (uint256 i; i < stakeHolders[_msgSender()].length; i++){
         uint256 gizmo = stakeHolders[_msgSender()][i];
         if (stakedTokens[gizmo].weiDue > 0) {
           due = due.add(stakedTokens[gizmo].weiDue);
           stakedTokens[gizmo].weiDue = 0;
           stakedTokens[gizmo].epochOfCalculation = 0;
         }
      }
      require(due > 0, "Nothing to claim");
      (bool success, ) = payable(_msgSender()).call{value: due}('');
      require(success);
    }

    function maxSupply() public view virtual returns (uint256) {
        return MAX_SUPPLY;
    }

    function maxMintPerTx() public view virtual returns (uint256) {
        return MAX_PER_TX;
    }

    function maxMintPerWallet() public view virtual returns (uint256) {
        return MAX_PER_WALLET;
    }
}