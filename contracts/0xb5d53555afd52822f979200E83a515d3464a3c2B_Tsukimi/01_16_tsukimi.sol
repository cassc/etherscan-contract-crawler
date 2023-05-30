// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721A.sol";
import "./ERC721AQueryable.sol";

contract Tsukimi is ERC721A, ERC721AQueryable, Ownable, ReentrancyGuard {
    constructor() ERC721A("Tsukimi", "TSUKIMI") {}

    event AllowlistSale(bool indexed _type);
    event PublicSale(bool indexed _type);

    mapping (address => uint256) private tokenBalance;

    address public allowlistSigner = 0x51F62DaA652D1827e6912d1B582F9d33Db465CfA;

    struct AllowlistSaleConfig {
        uint256 allowlistSaleStartTime;
        uint256 allowlistSaleEndTime;
        bool allowlistStarted;
    }

    AllowlistSaleConfig public allowlistSaleConfig;

    using ECDSA for bytes32;
    bytes32 private DOMAIN_VERIFICATION =
        keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("TsukimiLoft")),
                keccak256(bytes("1")),
                1,
                address(this)
            )
        );

    bool public isPublicSaleOn = false;
    string private _baseTokenURI;

    function isAllowlisted(address buyerWalletAddress, bytes memory _signature)
        public
        view
        returns (bool)
    {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_VERIFICATION,
                keccak256(
                    abi.encode(
                        keccak256(
                            "daydreamers(address buyerWalletAddress,string saleType)"
                        ),
                        buyerWalletAddress,
                        keccak256(bytes("allowlistSale"))
                    )
                )
            )
        );
        return
            ECDSA.recover(digest, _signature) == allowlistSigner ? true : false;
    }

    // sets allowlist signer
    function setAllowlistSigner(address _allowlistSigner) external onlyOwner {
        allowlistSigner = _allowlistSigner;
    }

    // toggles public sale
    function togglePublicSale() public onlyOwner {
        isPublicSaleOn = !isPublicSaleOn;
        emit PublicSale(isPublicSaleOn);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // sets base URI
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // starts allowlist sale
    function startAllowListSale(uint256 _durationInMinutes) external onlyOwner {
        allowlistSaleConfig = AllowlistSaleConfig(
            block.timestamp,
            block.timestamp + (_durationInMinutes * 60),
            true
        );
        emit AllowlistSale(true);
    }

    function stopAllowlistSale() external onlyOwner {
        allowlistSaleConfig = AllowlistSaleConfig(0, 0, false);
        emit AllowlistSale(false);
    }

    function allowListStarted() public view returns (bool) {
        AllowlistSaleConfig memory config = allowlistSaleConfig;
        return config.allowlistStarted;
    }

    function allowListTimeLeft() public view returns (uint256) {
        // returns time left in seconds
        AllowlistSaleConfig memory config = allowlistSaleConfig;
        uint32 startTime = uint32(config.allowlistSaleStartTime);
        uint32 endTime = uint32(config.allowlistSaleEndTime);
        if (block.timestamp >= startTime && block.timestamp <= endTime) {
            return endTime - block.timestamp;
        }
        return 0;
    }

    // dev mints
    function devMint(address _address, uint256 _amount) external onlyOwner {
        require(
            totalSupply() + _amount <= 5555,
            "Can't mint more than max supply"
        );
        _mint(_address, _amount);
    }

    function AllowlistMint(uint256 _amount, bytes memory _signature)
        public
        payable
    {
        require(allowListTimeLeft() > 0, "Allowlist sale is not active");

        require(
            isAllowlisted(msg.sender, _signature),
            "Address is not in allowlist"
        );

        require(
            totalSupply() + _amount <= 5555,
            "Can't mint more than max tokens"
        );

       require(
            2 >= tokenBalance[msg.sender] + _amount,
            "Max token count per wallet exceeded!"
        );
      

        _mint(msg.sender, _amount);
        tokenBalance[msg.sender]=tokenBalance[msg.sender]+_amount;
    }

    function mintPublicSale(uint256 _amount) public payable {
        require(isPublicSaleOn, "Public sale is not on");

        require(
            totalSupply() + _amount <= 5555,
            "Can't mint more than max tokens"
        );

       
        require(
            2 >= tokenBalance[msg.sender] + _amount,
            "Max token count per wallet exceeded!"
        );


        require(
            msg.value >= 0.02 ether * _amount,
            string(
                abi.encodePacked(
                    "Not enough ETH! At least ",
                    Strings.toString(0.02 ether * _amount),
                    " wei has to be sent!"
                )
            )
        );

        _mint(msg.sender, _amount);
        tokenBalance[msg.sender]=tokenBalance[msg.sender]+_amount;
    }

    function withdrawAll() public onlyOwner nonReentrant {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "");
    }

    function withdraw(uint256 _weiAmount, address _to)
        public
        onlyOwner
        nonReentrant
    {
        require(
            address(this).balance >= _weiAmount,
            "Not enough ETH to withdraw!"
        );
        (bool success, ) = payable(_to).call{value: _weiAmount}("");
        require(success, "");
    }
}