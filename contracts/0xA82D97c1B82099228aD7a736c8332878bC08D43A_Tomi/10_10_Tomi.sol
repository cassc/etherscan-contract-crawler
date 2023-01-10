// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./IPioneerNFT.sol";


contract Tomi is Initializable, ERC20Upgradeable, OwnableUpgradeable {
  
     // owner will be DAO, will need to approve every change.
    using SafeMathUpgradeable for uint256;

    struct emissionCriteria{
        // tomi mints before auction first 2 weeks of NFT Minting
       uint256 beforeAuctionBuyer;
       uint256 beforeAuctionCoreTeam;
       uint256 beforeAuctionMarketing;

        // tomi mints after two weeks // auction everyday of NFT Minting
       uint256 afterAuctionBuyer;
       uint256 afterAuctionFutureTeam;
       
       // booleans for checks of minting
       bool mintAllowed;
    }

    //  wallets
    address public marketingWallet;
    address public coreTeamWallet;
    address public futureTeamWallet;

    
    IPioneerNFT public nftContract;
    address public vestingContract;

    uint256 public totalMined;

    emissionCriteria public emissions;


    // modifiers to limit contract functionality
    modifier canMintNft{
        require(emissions.mintAllowed, "Minting is not Allowed as of now.");
        require(_msgSender() == address(nftContract), "Only NFT Contract");
        _;
    }

    modifier canMintVesting{
        require(_msgSender() == vestingContract, "Only Vesting Contract");
        _;
    }

    event marketingWalletUpdated(
        address indexed marketingWallet
    );

    event coreTeamWalletUpdated(
        address indexed tomiWallet
    );

    event futureTeamWalletUpdated(
        address indexed tomiWallet
    );

    event emissionUpdated(
        emissionCriteria indexed emissions
    );

    function initialize() initializer public {
        __ERC20_init("tomi Token", "TOMI");
        __Ownable_init();
    }

    function setValues(IPioneerNFT nftContract_, address marketingWallet_, address coreTeamWallet_,address futureTeamWallet_, address vestingContract_) public onlyOwner {
        nftContract = nftContract_;
        vestingContract = vestingContract_;
        marketingWallet = marketingWallet_;
        coreTeamWallet = coreTeamWallet_;
        futureTeamWallet = futureTeamWallet_;
        emissions = emissionCriteria(18000 ether, 39000 ether, 8000 ether, 18000 ether, 17000 ether, true);
    }


    // DAO Voting Functions
    function updateMarketingWallet(address newAddress) external onlyOwner {
        marketingWallet = newAddress;
        emit marketingWalletUpdated(newAddress);
    }

    function updateCoreTeamWallet(address newAddress) external onlyOwner {
        coreTeamWallet = newAddress;
        emit coreTeamWalletUpdated(newAddress);
    }

    function updateFutureTeamWallet(address newAddress) external onlyOwner {
        futureTeamWallet = newAddress;
        emit futureTeamWalletUpdated(newAddress);
    }

    function updateEmissions(emissionCriteria calldata emissions_) external onlyOwner{
        emissions = emissions_;
        emit emissionUpdated(emissions);
    }


    // Contract Functions
    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != to, "Sending to yourself is disallowed");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        super._transfer(from, to, amount);
    }

    function mintThroughNft(address buyer, uint256 quantity) external canMintNft returns(bool){
        if(nftContract.hasAuctionStarted()){
            afterAuctionMint(buyer);
        }else{
            beforeAuctionMint(buyer , quantity);
        }
        return true;
    }

    function mintThroughVesting(address buyer, uint256 quantity) external canMintVesting returns(bool){
        _mint(buyer, quantity);
        return true;
    }

    function beforeAuctionMint(address buyer, uint256 quantity) internal {
        _mint(buyer, emissions.beforeAuctionBuyer.mul(quantity));
        _mint(marketingWallet, emissions.beforeAuctionMarketing.mul(quantity));
        _mint(coreTeamWallet, emissions.beforeAuctionCoreTeam.mul(quantity));
    }

    function afterAuctionMint(address buyer) internal {
        _mint(buyer, emissions.afterAuctionBuyer);
        _mint(futureTeamWallet, emissions.afterAuctionFutureTeam);
    }
}