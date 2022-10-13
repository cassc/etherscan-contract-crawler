// contracts/Minter.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {AggregatorV3Interface} from "contracts/chainlink/AggregatorV3Interface.sol";
import "contracts/TokenizedMetalInterface.sol";
import "contracts/BullionBar.sol";

/*
 * There is a separate minter contract for each PM token.
 */
contract Minter is Ownable {
    using SafeMath for uint256;
    uint256 private constant MPIP_DIVIDER = 10000000;

    bool public chainlinkActive;
    AggregatorV3Interface private s_feed;
    uint256 private s_heartbeat;

    address[] public minters;    
    mapping (address => bool) public isMinter;
    TokenizedMetalInterface public tokenContract;
    BullionBar public bullionBar;
    uint256 public mintingFee;    

    modifier onlyMinter() {
        require(
            isMinter[msg.sender],
            "Only a minter can call this function"
        );
        _;
    }

    event MintingFeeChanged(uint256 mintingFee_);

    constructor(
        bool chainlinkActive_,
        address feedAddr_,
        uint256 heartbeat_
    ) {
        chainlinkActive = chainlinkActive_;
        s_feed = AggregatorV3Interface(feedAddr_);
        s_heartbeat = heartbeat_;
    }    

    /*
     * Set the chainlink parameters
     */
    function setChainlinkParameters(
        bool chainlinkActive_,
        address feedAddr_,
        uint256 heartbeat_
    ) external onlyOwner {
        chainlinkActive = chainlinkActive_;
        s_feed = AggregatorV3Interface(feedAddr_);
        s_heartbeat = heartbeat_;        
    }

    /*
     * Owner can set the minting fee in MPIP_DIVIDER
     */
    function setMintingFee(uint256 mintingFee_) external onlyOwner {
        mintingFee = mintingFee_;
        emit MintingFeeChanged(mintingFee_);
    }    

    /*
     * Owner can set the token contract
     */
    function setTokenContract(address tokenContractAddress_) external onlyOwner {
        require(tokenContractAddress_ != address(0), "Token contract cannot be null");
        tokenContract = TokenizedMetalInterface(tokenContractAddress_);
    }

    /*
     *  Set the bullion bar address
     */
    function setBullionBarAddress(address bullionBarAddress_) external onlyOwner {
        require(bullionBarAddress_ != address(0), "Bullion bar contract address cannot be null");
        bullionBar = BullionBar(bullionBarAddress_);
    }    

    /*
     * Owner can add a minter
     */
    function addMinter(address minter_) external onlyOwner {
        require(minter_ != address(0), "Minter cannot be null");
        minters.push(minter_);
        isMinter[minter_] = true;
    }

    /*
     * Owner can remove minter
     */
    function removeMinter(address minter_, uint256 index_) external onlyOwner {
        minters.push(minter_);
        require(index_ < minters.length, "Cannot find minter to remove");
        minters[index_] = minters[minters.length-1];
        minters.pop();
        isMinter[minter_] = false;
    }

    function _mintBars(
        address barBeneficiary_,
        string[] memory barCommodity_,
        string[] memory barRefiner_,
        string[] memory barMinter_,
        string[] memory barVault_,
        string[] memory barIdentifier_,
        uint256[] memory barWeight_) internal 
        returns (uint256 totalBarWeight) {
        uint256 nftId = bullionBar.getLastTokenId();

        for (uint256 i = 0; i< barIdentifier_.length; i++) {
            uint256 barWeight = barWeight_[i];

            bullionBar.mintBar(
                barBeneficiary_, 
                barCommodity_[i], 
                barRefiner_[i], 
                barMinter_[i], 
                barVault_[i], 
                barIdentifier_[i], 
                barWeight
            );        

            totalBarWeight = totalBarWeight.add(barWeight);
            nftId++;
        }              
        return totalBarWeight;
    }

    function mintTokens(
        address beneficiary_, 
        string[] memory barCommodity_, 
        string[] memory barRefiner_, 
        string[] memory barMinter_, 
        string[] memory barVault_, 
        string[] memory barIdentifier_, 
        uint256[] memory barWeight_) external onlyMinter {
        
        uint256 amount = _mintBars(beneficiary_, barCommodity_, barRefiner_, barMinter_, barVault_ ,barIdentifier_, barWeight_);
        if (chainlinkActive) {
            _chainlink(amount);
        }
        
        tokenContract.mintTokens(amount);
        tokenContract.transfer(beneficiary_, amount.sub(amount.mul(mintingFee).div(MPIP_DIVIDER)));
        tokenContract.transfer(tokenContract.getFeeCollectionAddress(), amount.mul(mintingFee).div(MPIP_DIVIDER));
    }    

    function _chainlink(uint256 amount_) internal view {

        // Chainlink
        (, int256 answer, , uint256 updatedAt, ) = s_feed.latestRoundData();
        require(answer > 0, "invalid answer from PoR feed");
        require(updatedAt >= block.timestamp - s_heartbeat, "answer outdated");

        uint256 reserves = uint256(answer);
        uint256 currentSupply = tokenContract.totalSupply();        

        uint8 trueDecimals = tokenContract.decimals();
        uint8 reserveDecimals = s_feed.decimals();
        // Normalise currencies
        if (trueDecimals < reserveDecimals) {
            currentSupply =
                currentSupply *
                10**uint256(reserveDecimals - trueDecimals);
        } else if (trueDecimals > reserveDecimals) {
            reserves = reserves * 10**uint256(trueDecimals - reserveDecimals);
        }
        require(
            currentSupply + amount_ <= reserves,
            "total supply would exceed reserves after mint"
        );
        // End chainlink
    }
}