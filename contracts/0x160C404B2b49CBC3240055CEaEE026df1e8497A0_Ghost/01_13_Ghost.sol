//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**************************************************
 * Ghost.sol
 *
 * Modified for PXN by: moodi
 * Originally Written by: mousedev.eth
 * Dutch Auction style inspired by: 0xinuarashi
 *
 * Special thanks goes to: Mousedev, KAI, woof
 ***************************************************
 */

contract Ghost is Ownable, ERC721A {
    using ECDSA for bytes32;

    //Base Extension
    string public constant baseExtension = ".json";

    //DA active variable
    bool public DA_ACTIVE = false;

    //Starting at 2 ether
    uint256 public constant DA_STARTING_PRICE = 2 ether;

    //Ending at 0.1 ether
    uint256 public constant DA_ENDING_PRICE = 0.1 ether;

    //Decrease by 0.05 every frequency.
    uint256 public constant DA_DECREMENT = 0.05 ether;

    //decrement price every 900 seconds (15 minutes).
    uint256 public constant DA_DECREMENT_FREQUENCY = 900;

    //Starting DA time (seconds).
    uint256 public DA_STARTING_TIMESTAMP = 1651719600; 

    //The final auction price.
    uint256 public DA_FINAL_PRICE;

    //WL Price
    uint256 public WLprice = 0.35 ether;

    //The quantity for DA.
    uint256 public constant DA_QUANTITY = 4000; 

    //The quantity for WL.
    uint256 public WL_QUANTITY = 6000;

    //How many publicWL have been minted
    uint16 public PUBLIC_WL_MINTED;

    address public constant FOUNDER_ADD = 0x21F169f44597B7579eb46b84DBE3Dd85f2818D87;
    address public constant DEV_FUND = 0xA7A8611a2D7663b3e215bB73f5fD57C9e673B2d8;

    //+86400 so it takes place 24 hours after Dutch Auction
    uint256 public WL_STARTING_TIMESTAMP = DA_STARTING_TIMESTAMP + 86400;

    //Struct for storing batch price data.
    struct TokenBatchPriceData {
        uint128 pricePaid;
        uint8 quantityMinted;
    }

    //Token to token price data
    mapping(address => TokenBatchPriceData[]) public userToTokenBatchPriceData;

    mapping(address => bool) public userToHasMintedPublicWL;

    //team WL list
    mapping(address => uint256) public _teamList;

    bool public REVEALED = false;
    string public BASE_URI;

    //WL signer for verification
    address private wlSigner;
    //DA signer for verification
    address private daSigner;
    // contract mint only
    bool private directMintAllowed = false;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor() ERC721A("projectPXN", "GHOST") {} 

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

    function mintDutchAuction(uint8 quantity, bytes calldata signature)
        public
        payable
        callerIsUser
    {
        require(DA_ACTIVE == true, "DA isnt active");
        if (!directMintAllowed) {
            require(
                daSigner ==
                    keccak256(
                        abi.encodePacked(
                            "\x19Ethereum Signed Message:\n32",
                            bytes32(uint256(uint160(msg.sender)))
                        )
                    ).recover(signature),
                "Signer address mismatch."
            );
        }
        //Max supply
        require(
            totalSupply() + quantity <= DA_QUANTITY,
            "Max supply for DA reached!"
        );
        //Require DA started
        require(
            block.timestamp >= DA_STARTING_TIMESTAMP,
            "DA has not started!"
        );
        require(block.timestamp <= WL_STARTING_TIMESTAMP, "DA is finished.");
        //Require max 2 per tx
        require(quantity <= 2, "Can only mint max 2 NFTs!");
        require(
            _numberMinted(msg.sender) + quantity <= 2,
            "Can only mint max 2 NFTs!"
        );

        uint256 _currentPrice = currentPrice();
        //Require enough ETH
        require(
            msg.value >= quantity * _currentPrice,
            "Did not send enough eth."
        );

        //This calculates the final price
        if (totalSupply() + quantity == DA_QUANTITY) {
            DA_FINAL_PRICE = _currentPrice;
            if (((DA_FINAL_PRICE / 100) * 50) < WLprice) {
                WLprice = ((DA_FINAL_PRICE / 100) * 50);
            }
        }

        userToTokenBatchPriceData[msg.sender].push(
            TokenBatchPriceData(uint128(msg.value), quantity)
        );

        //Mint the quantity
        _safeMint(msg.sender, quantity);
    }

    function mintWL(bytes calldata signature) public payable callerIsUser {
        require(DA_FINAL_PRICE > 0, "Dutch action must be over!");
        require(
            wlSigner ==
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        bytes32(uint256(uint160(msg.sender)))
                    )
                ).recover(signature),
            "Signer address mismatch."
        );
        require(PUBLIC_WL_MINTED + 1 <= WL_QUANTITY, "Max supply of 6000 for WL!");
        require(
            !userToHasMintedPublicWL[msg.sender],
            "Can only mint once during WL!"
        );
        require(
            block.timestamp >= WL_STARTING_TIMESTAMP,
            "WL minting has not started yet!"
        );
        require(
            block.timestamp <= WL_STARTING_TIMESTAMP + 86400,
            "WL minting has finished!"
        );
        require(msg.value >= WLprice, "Must send enough eth for WL Mint");

        userToHasMintedPublicWL[msg.sender] = true;
        PUBLIC_WL_MINTED++;

        //Mint them
        _safeMint(msg.sender, 1);
    }

    //send remaining NFTs to walet
    function devMint() external onlyOwner {
        require(
            block.timestamp >= WL_STARTING_TIMESTAMP + 86400,
            "WL hasnt finished!"
        );
        uint256 leftOver = 10000 - totalSupply();
        while (leftOver > 10) {
            _safeMint(DEV_FUND, 10);
            leftOver -= 10;
        }
        if (leftOver > 0) {
            _safeMint(DEV_FUND, leftOver);
        }
    }

    //team mint
    function teamMint(uint8 quantity) public payable {
        require(block.timestamp >= WL_STARTING_TIMESTAMP, "Team Mint hasnt started!");
        require(_teamList[msg.sender] >= quantity, "Already claimed.");
        require(
            msg.value >= quantity * WLprice,
            "Must send enough eth for Team Mint"
        );
        require(totalSupply() + quantity <= 10000, "Exceeds supply.");
        _teamList[msg.sender] = _teamList[msg.sender] - quantity;
        _safeMint(msg.sender, quantity);
    }

    //set team mint
    function setTeamMint(address[] calldata _addresses, uint8 amount)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _teamList[_addresses[i]] = amount;
        }
    }

    function readTeamMint(address user) public view returns (uint256) {
        return _teamList[user];
    }

    function userToTokenBatch(address user)
        public
        view
        returns (TokenBatchPriceData[] memory)
    {
        return userToTokenBatchPriceData[user];
    }

    function withdrawFunds() public onlyOwner {
        uint256 finalFunds = address(this).balance;
        payable(FOUNDER_ADD).transfer((finalFunds * 5000) / 10000);
        payable(DEV_FUND).transfer((finalFunds * 5000) / 10000);
    }

    function setDaFinalPrice(uint256 newPrice) external onlyOwner {
        DA_FINAL_PRICE = newPrice;
    }

    function setWLPrice(uint256 newPrice) external onlyOwner {
        WLprice = newPrice;
    }
    
    function setWLSigners(address signer) external onlyOwner {
        wlSigner = signer;
    }

    function setDASigners(address signer) external onlyOwner {
        daSigner = signer;
    }

    // control override
    function setDirectMintAllowance(bool _allowDirect) external onlyOwner {
        directMintAllowed = _allowDirect;
    }

    function setDutchActionActive(bool daActive) external onlyOwner {
        DA_ACTIVE = daActive;
    }

    function setRevealData(bool _revealed) external onlyOwner {
        REVEALED = _revealed;
    }

    function setStartTime(uint256 startTime) external onlyOwner {
        DA_STARTING_TIMESTAMP = startTime;
        WL_STARTING_TIMESTAMP = startTime + 86400;
    }

    function setWLSupply(uint16 quantity) external onlyOwner {
        WL_QUANTITY = quantity;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        BASE_URI = _baseURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        ); 
        if (!REVEALED) return BASE_URI;
        return
            string(
                abi.encodePacked(
                    BASE_URI,
                    Strings.toString(_tokenId),
                    baseExtension
                )
            );
    }
}