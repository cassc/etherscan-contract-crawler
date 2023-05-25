// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../utils/Startable.sol";


contract DustlandGoesApe is ERC721A, Ownable, Startable{
    
    uint256 public constant MAX_PER_MINT = 3;
    uint256 public constant MAX_TOKENS_PER_WALLET = 3;
    uint256 public constant RESERVED_TOKENS = 51;

    mapping(address => uint256) private _totalClaimed;
    mapping(address => bool) private _whitelist;
    mapping(uint256 => bool) private _signatureIds;

    address public payoutToken;
    uint256 public unitPrice;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public reservedClaimed;

    string internal _baseTokenURI;
    address internal _payeeWallet;
    address internal _signerAddress;

    event BaseURIChanged(string baseURI);

    constructor(string memory name_, string memory symbol_, address payeeWallet_, address payoutToken_, string memory baseURI) ERC721A(name_, symbol_) Ownable() {
        _payeeWallet = payeeWallet_;
        payoutToken = payoutToken_;
        _baseTokenURI = baseURI;
    }

    function startSale(uint256 startTime_, uint256 duration) external onlyOwner{
        require(startTime_ >= block.timestamp, "invalid start time");
        startTime = startTime_;
        endTime = startTime + duration; 
        _start();
    }

    function endSale() external onlyOwner{
        if(endTime > block.timestamp){
            endTime = block.timestamp; 
        }
        _end();
    }

    function addWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i=0; i < addresses.length; i++) {
            _whitelist[addresses[i]] = true;
        }
    }

    function checkWhitelist(address addr) external view returns (bool) {
        return _whitelist[addr];
    }

    function mint(uint256 count) external{
        require(_whitelist[_msgSender()], "not on whitelist");

        _mintToken(count);
    }

    function mint(uint256 count, uint256 _signatureId, bytes memory _signature) external{
        require(_signerAddress != address(0), "no assigned signer");
        require(!_signatureIds[_signatureId], "signatureId already used");
        require(
            checkSignature(_msgSender(), _signatureId, address(this), block.chainid, _signature) == _signerAddress,
            "signature failed"
        );
        _signatureIds[_signatureId] = true;
        
        _mintToken(count);
    }

    function _mintToken(uint256 count) internal whenStarted{
        require(block.timestamp <= endTime && block.timestamp >= startTime, "not in sale");
        require(count <= MAX_PER_MINT, "exceed max per mint");
        require(_totalClaimed[_msgSender()] + count <= MAX_TOKENS_PER_WALLET, "exceed max mint per wallet");
        require(count > 0, "mint at least one");
        require(unitPrice > 0, "worng price");

        _totalClaimed[_msgSender()] += count;
        SafeERC20.safeTransferFrom(IERC20(payoutToken), _msgSender(), _payeeWallet, unitPrice * count);

        _safeMint(_msgSender(), count);
    }

    function claimReserved(address recipient, uint256 count) external onlyOwner {
        require(reservedClaimed + count <= RESERVED_TOKENS, "minting will exceed max reserved tokens");
        require(recipient != address(0), "address cannot be null");

        reservedClaimed += count;
        _safeMint(recipient, count);
    }

    function burn(uint256 tokenId) external virtual {
        _burn(tokenId, true);
    }

    function checkSignature(
        address _wallet,
        uint256 _signatureId,
        address _contractAddress,
        uint256 _chainId,
        bytes memory _signature
    ) public pure returns (address) {
        return
            ECDSA.recover(
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        keccak256(abi.encode(_wallet, _signatureId, _contractAddress, _chainId))
                    )
                ),
                _signature
            );
    }

    function getClaimed(address user) view public returns (uint256){
        return _totalClaimed[user];
    }

    function saleLive() view public returns (bool){
        return started() && block.timestamp >= startTime && block.timestamp <= endTime;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
        emit BaseURIChanged(baseURI);
    }

    function setPrice(uint256 newPrice) public onlyOwner {
		unitPrice = newPrice;
	}

    function setPayeeWallet(address payeeWallet_) public onlyOwner {
		_payeeWallet = payeeWallet_;
	}

    function setPayoutToken(address payoutToken_) public onlyOwner {
		payoutToken = payoutToken_;
	}

    function setSignerAddress(address signerAddress_) external onlyOwner {
        _signerAddress = signerAddress_;
    }
}