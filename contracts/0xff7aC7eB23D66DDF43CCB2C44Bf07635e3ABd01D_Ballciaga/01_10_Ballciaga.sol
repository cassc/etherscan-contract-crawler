// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interface/IPlayerCardNFT.sol";
import "./Authorizer.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Ballciaga is Ownable, ReentrancyGuard, Authorizer {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    enum PackageType { Case, Box, Pack }

    struct Package {
        uint id; // Package ID
        PackageType packageType; // type
        uint start; // starting id
    }

     struct Invitee {
        address addr; // Invitee's address
        uint time; // Invite time
    }

    mapping(address => bool) public mintAddrMapping;

    mapping(address => Invitee[]) public inviteeListMapping;

    mapping(address => uint) public claimedPkgMapping; 

    uint public immutable packRefCnt;
    
    uint public pkgCnt;

    uint public nftCnt;

    uint public immutable totalNft;

    bool public canMint;

    uint public accumulatedFund;

    mapping(PackageType => uint) public countMapping;
    
    mapping(PackageType => uint) public priceMapping;

    IPlayerCardNFT public nftCard;

    // fund pool
    address public fundPool;
    address public profitPool;
    uint public profitPercent;

    mapping(address => Package[]) holderMapping;
    mapping(address => bool) public contributorClaimed;

    // 0
    address constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;

    event Mint(address indexed user, uint quantity, PackageType pkgType, uint start);
    
    event ClaimPack(address indexed user, uint quantity);

    // event ClaimContributionPack(address indexed user, uint quantity);

    constructor(
        address _nftAddr, 
        address _fundPoolAddr, 
        address _profitPoolAddr, 
        uint _casePrice,
        uint _boxPrice,
        uint _packPrice,
        uint _packRefCnt
    ) {
        nftCard = IPlayerCardNFT(_nftAddr);
        fundPool = _fundPoolAddr;
        profitPool = _profitPoolAddr;
        // init count for each pkg's type
        countMapping[PackageType.Case] = 100;
        countMapping[PackageType.Box] = 25;
        countMapping[PackageType.Pack] = 5;
        
        // init price
        priceMapping[PackageType.Case] = _casePrice;
        priceMapping[PackageType.Box] = _boxPrice;
        priceMapping[PackageType.Pack] = _packPrice;

        packRefCnt = _packRefCnt; 
        totalNft = 150000;
        profitPercent = 0;
        canMint = true;
    }

    function mint(uint quantity, PackageType pkgType, address refer) public payable {
        require(canMint, "It's not mining time");
        require(priceMapping[pkgType].mul(quantity) <= msg.value, 'Payment is not enough' );
        require(countMapping[pkgType] <= totalNft - nftCnt, 'The package of this type is sold out');
        require(countMapping[pkgType].mul(quantity) <= totalNft - nftCnt, 'The stock of this package type is not enough');

        address addr = msg.sender;

        for (uint256 i = 0; i < quantity; i++) {
            holderMapping[addr].push(Package({
                id: pkgCnt++,
                packageType: pkgType,
                start: nftCnt
            }));

            nftCnt += countMapping[pkgType];
        }

        nftCard.mintTo(addr, quantity * countMapping[pkgType]);
        
         if (refer != ZERO_ADDRESS && !mintAddrMapping[addr] && msg.sender != refer) {
            inviteeListMapping[refer].push(Invitee({
                addr: addr,
                time: block.timestamp
            }));
        }
        
        mintAddrMapping[addr] = true;

        uint profit = msg.value.mul(profitPercent).div(100);
        if (profit != 0) {
            payable(profitPool).transfer(profit);
        }
        payable(fundPool).transfer(msg.value.sub(profit));
        accumulatedFund = accumulatedFund.add(msg.value.sub(profit));

        emit Mint(addr, quantity, pkgType, nftCnt);
    }

    // for invitor
    function claimPack() public {
        address addr = msg.sender;
        uint quantity = inviteeListMapping[addr].length / packRefCnt - claimedPkgMapping[addr];

        require(canMint, "It's not mining time");
        require(quantity >= 1, 'there is no pack to claim');
        require(countMapping[PackageType.Pack] <= totalNft - nftCnt, 'The package of this type is sold out');
        require(countMapping[PackageType.Pack].mul(quantity) <= totalNft - nftCnt, 'The stock of this package type is not enough');

        claimedPkgMapping[addr] += quantity;

        for (uint256 i = 0; i < quantity; i++) {
            holderMapping[addr].push(Package({
                id: pkgCnt++,
                packageType: PackageType.Pack,
                start: nftCnt
            }));
             nftCard.mintTo(addr, countMapping[PackageType.Pack]);
             nftCnt += countMapping[PackageType.Pack];
        }

        emit ClaimPack(addr, quantity);
    }

    function claimContributionPack(uint256 quantity, uint256 underBlock, bytes memory signature) external {

        address receiver = msg.sender;

        require(canMint, "It's not mining time");
        require(block.number <= underBlock, "The signature has expired");
        require(!contributorClaimed[receiver], "You cannot claim it twice.");
        require(countMapping[PackageType.Pack].mul(quantity) <= totalNft - nftCnt, 'The stock of this package type is not enough');

        contributorClaimed[receiver] = true;

        bytes32 message = prefixed(keccak256(abi.encodePacked(receiver, quantity, underBlock, address(this))));
        
        address recoveredAddr = recoverSigner(message, signature);
        require(recoveredAddr == authorizer, "Invalid signature");
        
        for (uint256 i = 0; i < quantity; i++) {
            holderMapping[receiver].push(Package({
                id: pkgCnt++,
                packageType: PackageType.Pack,
                start: nftCnt
            }));
            nftCard.mintTo(receiver, countMapping[PackageType.Pack]);
            nftCnt += countMapping[PackageType.Pack];
        }

        emit ClaimPack(receiver, quantity);
    }

    function setCanMint(bool _canMint)  public onlyOwner {
        canMint = _canMint;
    }

    function setNftCard(address _nftCard) external onlyOwner {
        nftCard = IPlayerCardNFT(_nftCard);
    }

    function setFundPool(address _fundPoolAddr)  public onlyOwner {
        fundPool = _fundPoolAddr;
    }

    function setProfitPool(address _profitPoolAddr) public onlyOwner {
        profitPool = _profitPoolAddr;
    }

     function setProfitPercent(uint _profitPercent) public onlyOwner {
        profitPercent = _profitPercent;
    }

    function setPackagePrice(PackageType _type, uint _price)  public onlyOwner {
        priceMapping[_type] = _price;
      
    }
    
    function getTotalPackages(address _address) view public returns (Package[] memory pkgList) {
        pkgList = holderMapping[_address];
    }

   function getInviteeList(address _address) view public returns (Invitee[] memory inviteeList) {
        inviteeList = inviteeListMapping[_address];
    }

    function getTotalPackRewardCount(address _address) view public returns (uint) {
        uint quantity = inviteeListMapping[_address].length / packRefCnt;
        return quantity;
    }

    function getRestPackRewardCount(address _address) view public returns (uint) {
        uint quantity = getTotalPackRewardCount(_address) - claimedPkgMapping[_address];
        return quantity;
    }
}