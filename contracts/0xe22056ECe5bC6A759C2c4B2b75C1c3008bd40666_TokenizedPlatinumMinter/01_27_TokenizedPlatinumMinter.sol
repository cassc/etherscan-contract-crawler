// contracts/TokenizedPlatinumMinter.sol
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
contract TokenizedPlatinumMinter is Ownable {
    using SafeMath for uint256;
    uint256 private constant MPIP_DIVIDER = 10000000;
    string public constant COMMODITY = "platinum";

    bool public chainlinkActive;
    AggregatorV3Interface private s_feed;
    uint256 private s_heartbeat;

    address[] public minters;    
    mapping (address => bool) public isMinter;
    TokenizedMetalInterface public tokenContract;
    BullionBar public bullionBar;
    uint256 public mintingFee;    

    struct BarDetails {
        string identifier;
        string fineness;
        string vault;
        uint256 weight;
        bool minted;
    }

    BarDetails[] public bullionBars;

    modifier onlyMinter() {
        require(
            isMinter[msg.sender],
            "TokenizedPlatinumMinter: Only a minter can call this function"
        );
        _;
    }

    event MintingFeeChanged(uint256 mintingFee_);
    event MinterAdded(address indexed minterAddress_);
    event MinterRemoved(address indexed minterAddress_);

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
     * Owner can set the token contract and bullion bar contract
     */
    function setTokenContractAndBullionBarContract(address tokenContractAddress_, address bullionBarContractAddress_) external onlyOwner {
        require(tokenContractAddress_ != address(0), "Token contract cannot be null");
        require(bullionBarContractAddress_ != address(0), "Bullion bar contract address cannot be null");
        tokenContract = TokenizedMetalInterface(tokenContractAddress_);
        bullionBar = BullionBar(bullionBarContractAddress_);
    }

    /*
     * Owner can add a minter
     */
    function addMinter(address minterAddress_) external onlyOwner {
        require(minterAddress_ != address(0), "Minter cannot be null");
        minters.push(minterAddress_);
        isMinter[minterAddress_] = true;
        emit MinterAdded(minterAddress_);
    }

    /*
     * Owner can remove minter
     */
    function removeMinter(address minterAddress_, uint256 index_) external onlyOwner {
        minters.push(minterAddress_);
        require(index_ < minters.length, "Cannot find minter to remove");
        minters[index_] = minters[minters.length-1];
        minters.pop();
        isMinter[minterAddress_] = false;
        emit MinterRemoved(minterAddress_);
    }    

    function loadBarDetails(
        string calldata barIdentifier_,
        string calldata barFineness_,
        string calldata barVault_,    
        uint256 barWeight_
    ) public onlyMinter returns (uint256 barIndex) {
        bullionBars.push(BarDetails(
            barIdentifier_,
            barFineness_,
            barVault_,
            barWeight_,
            false
        ));
        return (bullionBars.length - 1);
    }    

    function _mintBars(
        address barBeneficiary_,
        uint256[] memory barIndexes_) internal 
        returns (uint256 totalBarWeight) {
            
        for (uint256 i = 0; i<barIndexes_.length; i++) {
            uint256 barId = barIndexes_[i];
            BarDetails memory bar = bullionBars[barId];
            require(bar.minted == false, "Bar already minted");            

            bullionBar.mintBar(
                barBeneficiary_, 
                COMMODITY,
                bar.identifier,
                bar.fineness,
                bar.vault,
                bar.weight
            );

            totalBarWeight = totalBarWeight.add(bar.weight);
            bar.minted = true;
            bullionBars[barId] = bar;
        }
        return totalBarWeight;
    }

    function mintTokens(
        address beneficiary_, 
        uint256[] memory barIndexes_) external onlyMinter {

        uint256 amount = _mintBars(beneficiary_, barIndexes_);
        if (chainlinkActive) {
            _chainlink(amount);
        }
        
        tokenContract.mintTokens(amount);
        uint256 mintingFeeAmount = (amount.mul(mintingFee)).div(MPIP_DIVIDER);
        amount = amount.sub(mintingFeeAmount);
        tokenContract.transfer(beneficiary_, amount);
        if (mintingFeeAmount > 0) {            
            tokenContract.transfer(tokenContract.getFeeCollectionAddress(), mintingFeeAmount);
        }
    }    

    function burnTokens(
        address tokenHolder_,
        address bullionBarHolder_,
        uint256[] memory tokenIds_) external onlyMinter {
        uint256 totalAmount = 0;
        for (uint256 i = 0; i< tokenIds_.length; i++) {
            uint256 tokenId = tokenIds_[i];
            uint256 barWeight = bullionBar.barWeight(tokenId);
            totalAmount = totalAmount.add(barWeight);
            bullionBar.transferFrom(bullionBarHolder_, address(this), tokenId);
            bullionBar.burnBar(tokenId);
        }
        tokenContract.transferFrom(tokenHolder_, address(this), totalAmount);
        tokenContract.burnTokens(totalAmount);

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