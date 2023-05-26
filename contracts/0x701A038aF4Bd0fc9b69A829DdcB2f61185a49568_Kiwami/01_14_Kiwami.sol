//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "./MerkleWhitelist.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*
Kiwami.sol

Written by: mousedev.eth
Dutch Auction style inspired by: 0xinuarashi

*/

contract Kiwami is Ownable, ERC721A, MerkleWhitelist {
    //Starting at 0.5 ether
    uint256 public DA_STARTING_PRICE = 0.5 ether;

    //Ending at 0.1 ether
    uint256 public DA_ENDING_PRICE = 0.1 ether;

    //Decrease by 0.05 every frequency.
    uint256 public DA_DECREMENT = 0.05 ether;

    //decrement price every 180 seconds (3 minutes).
    uint256 public DA_DECREMENT_FREQUENCY = 180;

    //Starting DA time (seconds).
    uint256 public DA_STARTING_TIMESTAMP = 1648080000;

    //The final auction price.
    uint256 public DA_FINAL_PRICE;

    //The quantity for DA.
    uint256 public DA_QUANTITY = 7000;

    //How many publicWL have been minted
    uint16 public PUBLIC_WL_MINTED;

    bool public INITIAL_FUNDS_WITHDRAWN;
    bool public REMAINING_FUNDS_WITHDRAWN;

    address public TEAM_USA_ADDRESS =
        0x0E861ddDA17f7C20996dC0868cAcc200bc1985c0;
    address public TEAM_JAPAN_ADDRESS =
        0xBC77EDd603bEf4004c47A831fDDa437cD906442E;
    address public MULTISIG_ADDRESS =
        0xBcAf5e757Ca1ef5F35fC2daBaDcb71dC7418A40D;

    //Contract URI
    string public CONTRACT_URI =
        "ipfs://QmNx5M7Dvgvg6ZNmUX6pdfD4NWZ7oh6RiP2F5b33TrPxCJ";

    //Struct for storing batch price data.
    struct TokenBatchPriceData {
        uint128 pricePaid;
        uint8 quantityMinted;
    }

    //Token to token price data
    mapping(address => TokenBatchPriceData[]) public userToTokenBatchPriceData;

    mapping(address => bool) public userToHasMintedPublicWL;
    mapping(address => bool) public userToHasMintedMiceWL;

    bool public REVEALED;
    string public UNREVEALED_URI =
        "ipfs://QmWQMuChCoTc2jKoDqCVHBxYe6pp1E2KMyW4HG8U7AA6wF";
    string public BASE_URI;

    uint256 public publicWLStartTime = 1648166400;
    uint256 public miceWLStartTime = 1648598400;

    constructor() ERC721A("Kiwami", "KIWAMI") {}

    function currentPrice() public view returns (uint256) {
        require(
            block.timestamp >= DA_STARTING_TIMESTAMP,
            "DA has not started!"
        );

        if (DA_FINAL_PRICE > 0) return DA_FINAL_PRICE;

        //Seconds since we started
        uint256 timeSinceStart = block.timestamp - DA_STARTING_TIMESTAMP;

        //How many decrements should've happened since that time
        uint256 decrementsSinceStart = timeSinceStart / DA_DECREMENT_FREQUENCY;

        //How much eth to remove
        uint256 totalDecrement = decrementsSinceStart * DA_DECREMENT;

        //If how much we want to reduce is greater or equal to the range, return the lowest value
        if (totalDecrement >= DA_STARTING_PRICE - DA_ENDING_PRICE) {
            return DA_ENDING_PRICE;
        }

        //If not, return the starting price minus the decrement.
        return DA_STARTING_PRICE - totalDecrement;
    }

    function mintDutchAuction(uint8 quantity) public payable {
        //Require DA started
        require(
            block.timestamp >= DA_STARTING_TIMESTAMP,
            "DA has not started!"
        );

        //Require max 5
        require(quantity > 0 && quantity < 6, "Can only mint max 5 NFTs!");

        uint256 _currentPrice = currentPrice();

        //Require enough ETH
        require(
            msg.value >= quantity * _currentPrice,
            "Did not send enough eth."
        );

        //Max supply
        require(
            totalSupply() + quantity <= DA_QUANTITY,
            "Max supply for DA reached!"
        );

        //This is the final price
        if (totalSupply() + quantity == DA_QUANTITY)
            DA_FINAL_PRICE = _currentPrice;

        userToTokenBatchPriceData[msg.sender].push(
            TokenBatchPriceData(uint128(msg.value), quantity)
        );

        //Mint the quantity
        _safeMint(msg.sender, quantity);
    }

    function mintPublicWL(bytes32[] memory proof)
        public
        payable
        onlyPublicWhitelist(proof)
    {
        require(DA_FINAL_PRICE > 0, "Dutch action must be over!");

        require(
            !userToHasMintedPublicWL[msg.sender],
            "Can only mint once during public WL!"
        );
        require(
            block.timestamp >= publicWLStartTime,
            "Public WL has not started yet!"
        );

        require(
            msg.value >= ((DA_FINAL_PRICE / 100) * 80),
            "Must send enough eth for WL Mint"
        );

        //Require max supply just in case.
        require(totalSupply() + 1 <= 8500, "Max supply of 8,500!");

        userToHasMintedPublicWL[msg.sender] = true;
        PUBLIC_WL_MINTED++;

        //Mint them
        _safeMint(msg.sender, 1);
    }

    function mintMouseWL(bytes32[] memory proof)
        public
        onlyMouseWhitelist(proof)
    {
        require(DA_FINAL_PRICE > 0, "Dutch action must be over!");
        require(
            !userToHasMintedMiceWL[msg.sender],
            "Can only mint once during mouse WL!"
        );
        require(
            block.timestamp >= miceWLStartTime,
            "Mice WL has not started yet!"
        );

        //Require max supply just in case.
        require(totalSupply() + 1 <= 10000, "Max supply of 10,000!");

        userToHasMintedMiceWL[msg.sender] = true;

        //Mint them
        _safeMint(msg.sender, 1);
    }

    function teamMint(uint256 quantity, address receiver) public onlyOwner {
        //Max supply
        require(
            totalSupply() + quantity <= 10000,
            "Max supply of 10,000 total!"
        );

        require(DA_FINAL_PRICE > 0, "Dutch action must be over!");

        //Mint the quantity
        _safeMint(receiver, quantity);
    }

    function userToTokenBatchLength(address user)
        public
        view
        returns (uint256)
    {
        return userToTokenBatchPriceData[user].length;
    }

    function refundExtraETH() public {
        require(DA_FINAL_PRICE > 0, "Dutch action must be over!");

        uint256 totalRefund;

        for (
            uint256 i = userToTokenBatchPriceData[msg.sender].length;
            i > 0;
            i--
        ) {
            //This is what they should have paid if they bought at lowest price tier.
            uint256 expectedPrice = userToTokenBatchPriceData[msg.sender][i - 1]
                .quantityMinted * DA_FINAL_PRICE;

            //What they paid - what they should have paid = refund.
            uint256 refund = userToTokenBatchPriceData[msg.sender][i - 1]
                .pricePaid - expectedPrice;

            //Remove this tokenBatch
            userToTokenBatchPriceData[msg.sender].pop();

            //Send them their extra monies.
            totalRefund += refund;
        }
        payable(msg.sender).transfer(totalRefund);
    }

    function withdrawInitialFunds() public onlyOwner {
        require(
            !INITIAL_FUNDS_WITHDRAWN,
            "Initial funds have already been withdrawn."
        );
        require(DA_FINAL_PRICE > 0, "DA has not finished!");

        uint256 DAFunds = DA_QUANTITY * DA_FINAL_PRICE;
        uint256 publicWLFunds = PUBLIC_WL_MINTED *
            ((DA_FINAL_PRICE / 100) * 80);

        uint256 initialFunds = DAFunds + publicWLFunds;

        INITIAL_FUNDS_WITHDRAWN = true;

        (bool succ, ) = payable(TEAM_USA_ADDRESS).call{
            value: (initialFunds * 15) / 100
        }("");
        require(succ, "transfer failed");

        (succ, ) = payable(TEAM_JAPAN_ADDRESS).call{
            value: (initialFunds * 35) / 100
        }("");
        require(succ, "transfer failed");

        (succ, ) = payable(MULTISIG_ADDRESS).call{
            value: (initialFunds * 50) / 100
        }("");
        
        require(succ, "transfer failed");
    }

    function withdrawFinalFunds() public onlyOwner {
        //Require this is 1 weeks after DA Start.
        require(block.timestamp >= DA_STARTING_TIMESTAMP + 604800);

        uint256 finalFunds = address(this).balance;

        (bool succ, ) = payable(TEAM_USA_ADDRESS).call{
            value: (finalFunds * 15) / 100
        }("");
        require(succ, "transfer failed");

        (succ, ) = payable(TEAM_JAPAN_ADDRESS).call{
            value: (finalFunds * 35) / 100
        }("");
        require(succ, "transfer failed");

        (succ, ) = payable(MULTISIG_ADDRESS).call{
            value: (finalFunds * 50) / 100
        }("");
        require(succ, "transfer failed");
    }

    function setRevealData(bool _revealed, string memory _unrevealedURI)
        public
        onlyOwner
    {
        REVEALED = _revealed;
        UNREVEALED_URI = _unrevealedURI;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        BASE_URI = _baseURI;
    }

    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        CONTRACT_URI = _contractURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (REVEALED) {
            return
                string(abi.encodePacked(BASE_URI, Strings.toString(_tokenId)));
        } else {
            return UNREVEALED_URI;
        }
    }
}