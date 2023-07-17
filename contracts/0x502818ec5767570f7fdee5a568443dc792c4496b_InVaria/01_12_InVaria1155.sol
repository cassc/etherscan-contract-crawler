// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//using Fix ERC1155,override _doSafeTransferAcceptanceCheck() function
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract InVaria is ERC1155, Ownable {
    using Strings for uint256;
    IERC20 public USDC;

    string private baseURI;
    //set return baseURI ID

    uint256 private TotalSupply = 10000;
    uint256 private Supply = 100;
    uint256 public SellingPrice = 2000 * 1e6;
    uint256 public Sold;



    mapping(uint256 => bool) public InVariaType;
    mapping(address => bool) public WhiteList;
    mapping(address => bool) private PreSaleBuyer;


    string private _name = "InVaria 2222";
    string private _symbol = "InVaria";


    bool public BurnRedemption = false;
    bool public PublicSale = false;

    address private USDC_address = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public WithDrawAddress = 0xAcB683ba69202c5ae6a3B9b9b191075295b1c41C;
    address private receiveAddress;
    address private StakingAddress;
    event SetBaseURI(string indexed _baseURI);

    constructor(string memory _baseURI) ERC1155(_baseURI) {
        USDC = IERC20(USDC_address);
        baseURI = _baseURI;
        InVariaType[1] = true;
        InVariaType[2] = true;
        emit SetBaseURI(baseURI);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view returns (uint) {
        return TotalSupply;
    }

    function SaleSupply() public view returns(uint256){
        return Supply;
    }

    function balanceOf(address account)external view returns(uint256){
        return balanceOf(account,1);
    }

    function CheckPreSaleBuyer(address account)public view returns(bool){
        return PreSaleBuyer[account];
    }


    //only owner

    function setType(uint256 types) external onlyOwner{
        InVariaType[types] = true;

    }
    function setUSDCaddress(address token)external onlyOwner{
         USDC = IERC20(token);
    }

    function setStakingAddress(address addr)external onlyOwner{
        StakingAddress = addr;

    }

    function setSupply(uint256 supply,uint256 total)external onlyOwner{
        Supply = supply;
        TotalSupply = total;
    }

    function AddWhite(address[] memory input,bool bo)external onlyOwner{
        for(uint256 a=0;a<input.length;a++){
            WhiteList[input[a]] = bo;
        }
    }

    function ChangeSalePrice(uint256 price)external onlyOwner{
        SellingPrice = price * 1e6;
    }
    function publicSaleStart(bool set)external onlyOwner{
        PublicSale = set;
    }

    function onwerMint()external onlyOwner{//only for testing
        _mint(msg.sender, 1, 5,"");
    }



    //user function

    function mintNFT(uint256 amounts)external{
        require(WhiteList[msg.sender],"You are not on the white list");
        require(amounts > 0,"Input amount can't be 0 ");
        require(Sold + amounts <= TotalSupply ,"Not enought NFT" );
        require(Sold + amounts <= Supply ,"Not enought NFT" );
        require(USDC.allowance(msg.sender,address(this)) >= amounts * SellingPrice,"Allowance insufficient");
        require(USDC.balanceOf(msg.sender) >= amounts * SellingPrice,"Not enought USDC");
        USDC.transferFrom(msg.sender, WithDrawAddress, amounts * SellingPrice);
        PreSaleBuyer[msg.sender] = true;

        Sold += amounts;

        _mint(msg.sender, 1, amounts,"");
    }

    function PublicMintNFT(uint256 amounts)external{
        require(PublicSale && amounts > 0,"Punbic sale not start yet");
        require(Sold + amounts <= TotalSupply ,"Not enought NFT" );
        require(Sold + amounts <= Supply ,"Not enought NFT" );
        require(USDC.allowance(msg.sender,address(this)) >= amounts * SellingPrice,"Allowance insufficient");
        require(USDC.balanceOf(msg.sender) >= amounts * SellingPrice,"Not enought USDC");
        USDC.transferFrom(msg.sender, WithDrawAddress, amounts * SellingPrice);
        Sold += amounts;

        _mint(msg.sender, 1, amounts,"");

    }



    function BurnInVariaNFT(address burnTokenAddress,uint256 burnValue)external{
        require(msg.sender == StakingAddress,"Not the staking address");
        require(balanceOf(burnTokenAddress,1) >= burnValue, "Invalid burner address");

        _burn(burnTokenAddress, 1, burnValue);
        _mint(burnTokenAddress, 2, burnValue,"");

    }


    function updateBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit SetBaseURI(baseURI);
    }


    //override

    function uri(uint256 typeId) public view override returns (string memory){
        require(
            InVariaType[typeId],
            "URI requested for invalid"
        );
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, typeId.toString(),".json")): baseURI;
    }


     function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {



        if(to != StakingAddress){
            require(
               from == _msgSender()||isApprovedForAll(from, _msgSender()),
                "ERC1155: caller is not approved nor owner"
            );
        }else{
            require(msg.sender == StakingAddress,"ERC1155: caller is not the Staking contract");
        }

        _safeTransferFrom(from, to, id, amount, data);
    }



}