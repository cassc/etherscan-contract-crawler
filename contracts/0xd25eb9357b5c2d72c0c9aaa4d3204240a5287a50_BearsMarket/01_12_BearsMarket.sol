// SPDX-License-Identifier: MIT


//********************************************************************************
//*******************@@@########@*******************@########@@@******************
//******************@############@****************@@##########((@*****************
//************%%%@((##@@@*(((@######@***********@#####@@((**@@###(@@**************
//********%%% %%@(##@%*******(((@###@(@@@@@@@@((@###@(((********@#((@*************
//********%%**%%....,%********@@(###################(@**********@#((@*************
//*******%,,%***@(##@*******@(%%%#####################((@*******@#((@*************
//********%%****@(###(@@*@((%%###########################(@@*@((##((@*************
//****************@@(###(%%%################################(###(@****************
//*******************@((%%###################################(@@******************
//*******************@((%%###########(########((#############(@@******************
//*******************@((%%##@*****@@@###########@@******@####(@@******************
//*******************@((%%##@****@  *@########@@*@  ****@####(@@******************
//*******************@((%%##@ *******@########@@******  @####(@@******************
//****************@@(%((%####@@@@@@@@@########@@@@@@@@@@####(#((@*****************
//*******************@%%#########(((*************(((############@*****************
//*******************@%%######((******%%((  (%*******(########@@******************
//*******************@%%####(***********%%%%%***********(#####@@******************
//******************@%%%####(***************************(#######@*****************
//******************@%%%%%###(((((###@@@@###@@@@##((((((########@*****************
//******************@%%%%%%%####################################@*****************
//*******************@@@%%@@@#@@#####################@###@###@@@******************
//****************@@(%%%%%#######@@@@@@@@@@@@@@@@@##############(@****************
//***************@((%%%%%#############((######((#################(@@**************
//***************@((%%%%%################(##(####################(@@**************

pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract BearsMarket is ERC721AQueryable, ERC721ABurnable, EIP712, Ownable {
    uint256 public maxSupply = 6000;
    uint256 public maxNormalMintPerAccount = 6;
    uint256 public maxWhitelistMintPerAccount = 4;
    uint256 public publicSalesTimestamp = 1669500000;
    uint256 public whitelistSalesTimestamp = 1669500000;
    uint256 public totalNormalMint;
    uint256 public totalWhitelistMint;
    uint256 public maxNormalSupply = 6000;
    uint256 public maxWhitelistSupply = 1200;
    uint256 public normalMintPrice = 0.003 ether;
    uint256 public whitelistMintPrice = 0.003 ether;

    mapping(address => uint256) private _totalNormalMintPerAccount;
    mapping(address => uint256) private _totalWhitelistMintPerAccount;

    address private _signerPublicKey = 0xce14c3dF9Dd5e5De736921E092BeBC08D48De365;

    string private _contractUri;
    string private _baseUri;

    constructor() ERC721A("Bears Market", "BM") EIP712("Bears Market", "1.0.0") {}

    function mint(uint256 amount) external payable {
        require(totalSupply() < maxSupply, "sold out");
        require(
            totalNormalMint < maxNormalSupply,
            "normal mint reached max supply"
        );
        require(isPublicSalesActive(), "sales is not active");
        require(amount > 0, "invalid amount");

        require(
            amount + totalNormalMint <= maxNormalSupply,
            "amount exceeds max supply"
        );
        require(
            amount + _totalNormalMintPerAccount[msg.sender] <=
                maxNormalMintPerAccount,
            "max tokens per account reached"
        );
        require(
            amount + totalSupply() <= maxSupply,
            "amount exceeds max supply"
        );


         if (((_totalNormalMintPerAccount[msg.sender] < 3) && (_totalNormalMintPerAccount[msg.sender] + amount >= 3) && (_totalNormalMintPerAccount[msg.sender] + amount < 6)) 
         || ((_totalNormalMintPerAccount[msg.sender] >= 3) && (_totalNormalMintPerAccount[msg.sender] + amount == 6) )) {
            require(msg.value >= (normalMintPrice * amount) - normalMintPrice, "Insufficient funds!");
        } else if (_totalNormalMintPerAccount[msg.sender] < 3 && _totalNormalMintPerAccount[msg.sender] + amount == 6) {
            require(msg.value >= (normalMintPrice * amount) - (2 * normalMintPrice), "Insufficient funds!");
        } else {
            require(msg.value >= (normalMintPrice * amount), "Insufficient funds!");
        }

        totalNormalMint += amount;
        _totalNormalMintPerAccount[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function batchMint(address[] calldata addresses, uint256[] calldata amounts)
        external
        onlyOwner
    {
        require(
            addresses.length == amounts.length,
            "addresses and amounts doesn't match"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
                    totalNormalMint += amounts[i];
            _safeMint(addresses[i], amounts[i]);
        }
    }

    function whitelistMint(uint256 amount, bytes calldata signature)
        external
        payable
    {
        require(totalSupply() < maxSupply, "sold out");
        require(
            totalWhitelistMint < maxWhitelistSupply,
            "whitelist mint reached max supply"
        );
        require(
            _recoverAddress(msg.sender, signature) == _signerPublicKey,
            "account is not whitelisted"
        );
        require(isWhitelistSalesActive(), "sales is not active");
        require(amount > 0, "invalid amount");
        require(
            amount + totalWhitelistMint <= maxWhitelistSupply,
            "amount exceeds max WL supply"
        );

        require(
            amount + totalSupply() <= maxSupply,
            "amount exceeds max supply"
        );

        require(
            amount + _totalWhitelistMintPerAccount[msg.sender] <=
                maxWhitelistMintPerAccount,
            "max tokens per account reached"
        );


        if (((_totalWhitelistMintPerAccount[msg.sender] < 2) && (_totalWhitelistMintPerAccount[msg.sender] + amount >= 2) && (_totalWhitelistMintPerAccount[msg.sender] + amount < 4)) 
         || ((_totalWhitelistMintPerAccount[msg.sender] == 3) && (_totalWhitelistMintPerAccount[msg.sender] + amount == 4) )) {
            require(msg.value >= (whitelistMintPrice * amount) - whitelistMintPrice, "Insufficient funds!");
        } else if (_totalWhitelistMintPerAccount[msg.sender] < 2 && _totalWhitelistMintPerAccount[msg.sender] + amount == 4) {
            require(msg.value >= (whitelistMintPrice * amount) - (2 * whitelistMintPrice), "Insufficient funds!");
        } else {
            require(msg.value >= (whitelistMintPrice * amount), "Insufficient funds!");
        }


        totalWhitelistMint += amount;
        _totalWhitelistMintPerAccount[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function isPublicSalesActive() public view returns (bool) {
        return publicSalesTimestamp <= block.timestamp;
    }

    function isWhitelistSalesActive() public view returns (bool) {
        return whitelistSalesTimestamp <= block.timestamp;
    }

    function hasMintedUsingWhitelist(address account)
        public
        view
        returns (bool)
    {
        return
            _totalWhitelistMintPerAccount[account] >=
            maxWhitelistMintPerAccount;
    }

    function totalNormalMintPerAccount(address account)
        public
        view
        returns (uint256)
    {
        return _totalNormalMintPerAccount[account];
    }

    function totalWhitelistMintPerAccount(address account)
        public
        view
        returns (uint256)
    {
        return _totalWhitelistMintPerAccount[account];
    }

    function contractURI() external view returns (string memory) {
        return _contractUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function setContractURI(string memory contractURI_) external onlyOwner {
        _contractUri = contractURI_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseUri = baseURI_;
    }

    function setSignerPublicKey(address signerPublicKey_) external onlyOwner {
        _signerPublicKey = signerPublicKey_;
    }

    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    function setMaxNormalSupply(uint256 maxNormalSupply_) external onlyOwner {
        maxNormalSupply = maxNormalSupply_;
    }

    function setMaxWhitelistSupply(uint256 maxWhitelistSupply_)
        external
        onlyOwner
    {
        maxWhitelistSupply = maxWhitelistSupply_;
    }

    function setNormalMintPrice(uint256 normalMintPrice_) external onlyOwner {
        normalMintPrice = normalMintPrice_;
    }

    function setWhitelistMintPrice(uint256 whitelistMintPrice_)
        external
        onlyOwner
    {
        whitelistMintPrice = whitelistMintPrice_;
    }

    function setMaxNormalMintPerAccount(uint256 maxNormalMintPerAccount_)
        external
        onlyOwner
    {
        maxNormalMintPerAccount = maxNormalMintPerAccount_;
    }

    function setMaxWhitelistMintPerAccount(uint256 maxWhitelistMintPerAccount_)
        external
        onlyOwner
    {
        maxWhitelistMintPerAccount = maxWhitelistMintPerAccount_;
    }

    function setPublicSalesTimestamp(uint256 timestamp) external onlyOwner {
        publicSalesTimestamp = timestamp;
    }

    function setWhitelistSalesTimestamp(uint256 timestamp) external onlyOwner {
        whitelistSalesTimestamp = timestamp;
    }

    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function _hash(address account) private view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("BearsMarket(address account)"),
                        account
                    )
                )
            );
    }

    function _recoverAddress(address account, bytes calldata signature)
        private
        view
        returns (address)
    {
        return ECDSA.recover(_hash(account), signature);
    }
}