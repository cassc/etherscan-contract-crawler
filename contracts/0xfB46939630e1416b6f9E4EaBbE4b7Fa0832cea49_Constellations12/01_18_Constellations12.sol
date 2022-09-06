// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Ownable
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

// local contract
import "./Withdrawable.sol";
import "./ERC721Opensea.sol";
import "./PublicSalesActivation.sol";

// Constellations12
contract Constellations12  is
    Ownable,
    PublicSalesActivation,
    Withdrawable,
    EIP712,
    ERC721Opensea
{

    // ------------------------------------------------------------------------------------------ event
    // If it's a free mint, emit this event
    event freeMintEvent( address );


    // ------------------------------------------------------------------------------------------ const
    // total sales
    uint256 public constant TOTAL_MAX_QTY = 8400;

    // max number of NFTs every wallet can buy
    uint256 public constant MAX_QTY_PER_MINTER = 84;

    // max sales quantity
    uint256 public constant SALES_MAX_QTY = TOTAL_MAX_QTY;

    // NFT price
    uint256 public constant SALES_PRICE = 0.008 ether;

    // ------------------------------------------------------------------------------------------ variable
    // for random
    uint256 internal seed = 9527;

    // minter
    mapping(address => uint256) public salesMinterToTokenQty;

    // sales quantity
    uint256 public salesMintedQty = 0;
    uint256 public giftedQty = 0;


    // init
    constructor() ERC721("Constellations12", "C12") EIP712("Constellations12", "1") {}

    // mint
    function mint(uint256 _mintQty)
        external
        isPublicSalesActive
        callerIsUser
        payable
    {
        require(
            salesMintedQty + _mintQty <= SALES_MAX_QTY,
            "Exceed sales max limit!"
        );
        require(
            salesMinterToTokenQty[msg.sender] + _mintQty <=  MAX_QTY_PER_MINTER,
            "Exceed max mint per minter!"
        );
        require(
            msg.value >= SALES_PRICE * _mintQty,
            "Insufficient money!  "
        );

        // get a random number, and it's free if the random number is less than 23
        if( random(100) < 23 ){
            // send back the money for free mint
            payable(msg.sender).transfer( msg.value );
            // emit a free mint event
            emit freeMintEvent(msg.sender);
        }

        // update the quantity of the sales
        salesMinterToTokenQty[msg.sender] += _mintQty;
        salesMintedQty += _mintQty;

        // safe mint for every NFT
        for (uint256 i = 0; i < _mintQty; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
        
    }


    function fillEth() external payable {}


    // get random that is between 0 to 'number'
    function random(int256 number) internal returns (int256) {
        if( 0 == number ) return 0;
        seed += 1;
        uint randomNum = uint(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    msg.sender,
                    seed
                )
            )
        );
        if( randomNum == 0 ) return 0;
        return int256( randomNum  % uint(number)  );
    }

    // not other contract
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "not user!");
        _;
    }



}