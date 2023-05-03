//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { LaunchpadEnabled } from "./LaunchpadEnabled.sol";
contract BasicMarketplace is Ownable, ReentrancyGuard, LaunchpadEnabled
{
    struct Sale
    {
        uint _Price;
        uint _MintPassProjectID;
        uint _Type;
        uint _ABProjectID;
        uint _AmountForSale;
        address _NFT;
        bytes32 _Root;
    }
    mapping(uint=>Sale) public Sales;
    mapping(uint=>uint) public AmountSold;
    mapping(uint=>uint[]) public DiscountAmounts;
    event Purchased(address Purchaser, uint Amount);

    /**
     * @dev Purchases An `Amount` Of NFTs From A `SaleIndex`
     */
    function Purchase(uint SaleIndex, uint Amount, bytes32[] calldata Proof) external payable nonReentrant
    {
        (bool Brightlist, uint Priority) = VerifyBrightList(SaleIndex, msg.sender, Sales[SaleIndex]._Root, Proof);
        if(Brightlist) 
        {
            require(msg.value == ((Sales[SaleIndex]._Price * DiscountAmounts[SaleIndex][Priority]) / 100), "BasicMarketplace: Incorrect ETH Amount Sent");
        }
        else
        {
            require(msg.value == Sales[SaleIndex]._Price * Amount, "BasicMarketplace: Incorrect ETH Amount Sent");
        }
        require(AmountSold[SaleIndex] + Amount <= Sales[SaleIndex]._AmountForSale, "BasicMarketplace: Not Enough NFTs Left For Sale");
        AmountSold[SaleIndex] = AmountSold[SaleIndex] + Amount;
        if(Sales[SaleIndex]._Type == 0) { IERC721(Sales[SaleIndex]._NFT)._MintToFactory(Sales[SaleIndex]._MintPassProjectID, msg.sender, Amount); }
        else 
        { 
            uint ProjectID = Sales[SaleIndex]._ABProjectID;
            for(uint x; x < Amount; x++) { IERC721(Sales[SaleIndex]._NFT).purchaseTo(msg.sender, ProjectID); }
        } 
        emit Purchased(msg.sender, Amount);
    }

    /**
     * @dev Changes The NFT Address Of A Sale
     */
    function __ChangeNFTAddress(uint SaleIndex, address NewAddress) external onlyOwner { Sales[SaleIndex]._NFT = NewAddress; }

    /**
     * @dev Changes The Price Of A Sale
     */
    function __ChangePrice(uint SaleIndex, uint Price) external onlyOwner { Sales[SaleIndex]._Price = Price; }

    /**
     * @dev Changes The MintPass ProjectID
     */
    function __ChangeMintPassProjectID(uint SaleIndex, uint MintPassProjectID) external onlyOwner { Sales[SaleIndex]._MintPassProjectID = MintPassProjectID; }

    /**
     * @dev Changes The ArtBlocks ProjectID
     */
    function __ChangeABProjectID(uint SaleIndex, uint ABProjectID) external onlyOwner { Sales[SaleIndex]._ABProjectID = ABProjectID; }

    /**
     * @dev Changes The Amount Of NFTs For Sale
     */
    function __ChangeAmountForSale(uint SaleIndex, uint AmountForSale) external onlyOwner { Sales[SaleIndex]._AmountForSale = AmountForSale; }

    /**
     * @dev Changes The Type Of A Sale
     */
    function __ChangeType(uint SaleIndex, uint Type) external onlyOwner { Sales[SaleIndex]._Type = Type; }

    /**
     * @dev Initializes A Sale Via A Struct
     */
    function __StartSale(uint SaleIndex, Sale memory _Sale) external onlyOwner { Sales[SaleIndex] = _Sale; }

    /**
     * @dev Initializes A Sale Via Parameters
     */
    function __StartSale(
        uint SaleIndex, 
        uint Price, 
        uint MintPassProjectID, 
        uint Type, 
        uint ABProjectID, 
        uint AmountForSale, 
        address NFT, 
        bytes32 Root
    ) external onlyOwner { Sales[SaleIndex] = Sale(Price, MintPassProjectID, Type, ABProjectID, AmountForSale, NFT, Root); }

    /**
     * @dev Withdraws ETH From The Contract
     */
    function WithdrawETH() external onlyOwner { payable(msg.sender).transfer(address(this).balance); }

    /**
     * @dev Withdraws ETH With A Low-Level Call
     */
    function WithdrawETHCall() external onlyOwner 
    { 
        (bool success,) = msg.sender.call { value: address(this).balance }(""); 
        require(success, "BasicMarketplace: ETH Withdraw Failed"); 
    }

    /**
     * @dev Verifies Brightlist
     */
    function VerifyBrightList(uint SaleIndex, address _Wallet, bytes32 _Root, bytes32[] calldata _Proof) public view returns (bool, uint)
    {
        bytes32 _Leaf = keccak256(abi.encodePacked(_Wallet));
        for(uint x; x < DiscountAmounts[SaleIndex].length; x++) { if(MerkleProof.verify(_Proof, _Root, _Leaf)) { return (true, x); } }
        return (false, 69420);
    }
}

interface IERC721
{
    function _MintToFactory(uint projectid, address to, uint amount) external;
    function purchaseTo(address _to, uint _projectID) external payable returns (uint _tokenId);
}