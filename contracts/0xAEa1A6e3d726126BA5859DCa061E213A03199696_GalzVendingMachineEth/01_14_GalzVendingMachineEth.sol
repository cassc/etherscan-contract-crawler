// SPDX-License-Identifier: MIT

/*
╋╋╋╋╋╋╋┏┓╋╋╋╋╋╋╋╋╋╋╋╋┏┓
╋╋╋╋╋╋╋┃┃╋╋╋╋╋╋╋╋╋╋╋╋┃┃
┏━━┳┓╋┏┫┗━┳━━┳━┳━━┳━━┫┃┏━━━┓
┃┏━┫┃╋┃┃┏┓┃┃━┫┏┫┏┓┃┏┓┃┃┣━━┃┃
┃┗━┫┗━┛┃┗┛┃┃━┫┃┃┗┛┃┏┓┃┗┫┃━━┫
┗━━┻━┓┏┻━━┻━━┻┛┗━┓┣┛┗┻━┻━━━┛
╋╋╋┏━┛┃╋╋╋╋╋╋╋╋┏━┛┃
╋╋╋┗━━┛╋╋╋╋╋╋╋╋┗━━┛
*/

// CyberGalz Legal Overview [https://cybergalznft.com/legaloverview]

pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract GalzVendingMachineImxInterface {
    function mintTransfer(address to) public virtual;
}

contract GalzVendingMachineEth is ERC721, ERC721Enumerable, Ownable { 
    using SafeMath for uint256;

    bool public sale = false;
    bool public presale = false;
    bool migrationStarted = false;

    string private _baseURIextended;

    uint256 public nonce = 1;
    uint256 public price = 200000000000000000;
    uint16 public earlySupply;
    uint16 public totalSupply_;
    uint8 public maxPublic;

    address public paymentAddress;
    address galzVendingMachineImxAddress;

    event PaymentComplete(address indexed to, uint16 nonce, uint16 quantity);
    event Minted(address indexed to, uint256 id);
    event Withdraw(uint amount);

    mapping (address => uint8) private presaleWallets;
    mapping (address => uint8) private saleWallets;

    constructor(
        string memory _name,
        string memory _ticker,
        uint16 _totalSupply,
        uint8 _maxPublic,
        string memory baseURI_,
        address _paymentAddress
    ) ERC721(_name, _ticker) {
        earlySupply = _totalSupply;
        totalSupply_ = _totalSupply;
        maxPublic = _maxPublic;
        _baseURIextended = baseURI_;
        paymentAddress = _paymentAddress;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setPrice(uint _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setEarlySupply(uint16 _limitSupply) external onlyOwner {
        earlySupply = _limitSupply;
    }

    function setTotalSupply(uint16 _newSupply) external onlyOwner {
        totalSupply_ = _newSupply;
    }

    function togglePresale() public onlyOwner {
        presale = !presale;
    }

    function toggleSale() public onlyOwner {
        sale = !sale;
    }

    function setMaxPublic(uint8 _maxPublic) external onlyOwner {
        maxPublic = _maxPublic;
    }

    function setPresaleWalletsAmounts(address[] memory _a, uint8[] memory _amount) public onlyOwner {
        require(_a.length == _amount.length, "invalid param length");
        for (uint256 i = 0; i < _a.length; i++) {
            presaleWallets[_a[i]] = _amount[i];
        }
    }

    function getPresaleWalletAmount(address _wallet) public view onlyOwner returns(uint8) {
        return presaleWallets[_wallet];
    }

    function getSaleWalletAmount(address _wallet) public view onlyOwner returns(uint8) {
        return saleWallets[_wallet];
    }

    function buyPresale(uint8 _qty) external payable {
        uint8 _qtyAllowed = presaleWallets[msg.sender];
        require(presale, 'Presale is not active');
        require(uint16(_qty) + nonce - 1 <= earlySupply, 'No more supply');
        require(uint16(_qty) + nonce - 1 <= totalSupply_, 'No more supply');
        require(_qty <= _qtyAllowed, 'You can not buy more than allowed');
        require(_qtyAllowed > 0, 'You can not mint on presale');
        require(msg.value >= price * _qty, 'Invalid price value');

        presaleWallets[msg.sender] = _qtyAllowed - _qty;

        payable(paymentAddress).transfer(msg.value);
        uint16 initialTokenId = uint16(nonce);
        nonce = nonce + uint256(_qty);
        emit PaymentComplete(msg.sender, initialTokenId, _qty);

        for(uint256 i = 0; i < _qty; i++ ) {
            _safeMint(msg.sender, initialTokenId + i);
            emit Minted(msg.sender, initialTokenId + i);
        }
    }

    function buy(uint8 _qty) external payable {
        uint8 _qtyMinted = saleWallets[msg.sender];
        require(sale, 'Sale is not active');
        require(uint16(_qty) + nonce - 1 <= earlySupply, 'No more supply');
        require(uint16(_qty) + nonce - 1 <= totalSupply_, 'No more supply');
        require(_qtyMinted + _qty <= maxPublic, 'You can not buy more than allowed');
        require(_qty > 0, "quantity should be positive number");
        require(_qty <= maxPublic, 'You can not buy more than allowed');
        require(msg.value >= price * _qty, 'Invalid price value');

        saleWallets[msg.sender] = saleWallets[msg.sender] + _qty;

        uint16 initialTokenId = uint16(nonce);
        nonce = nonce.add(_qty);
        payable(paymentAddress).transfer(msg.value);

        emit PaymentComplete(msg.sender, initialTokenId, _qty);

        for(uint256 i = 0; i < _qty; i++ ) {
            _safeMint(msg.sender, initialTokenId + i);
            emit Minted(msg.sender, initialTokenId + i);
        }
    }

    function giveaway(address _to, uint8 _qty) external onlyOwner {
        require(uint16(_qty) + nonce - 1 <= totalSupply_, 'No more supply');

        uint16 initialTokenId = uint16(nonce);
        nonce = nonce.add(_qty);

        emit PaymentComplete(_to, initialTokenId, _qty);

        for(uint256 i = 0; i < _qty; i++ ) {
            _safeMint(_to, initialTokenId + i);
            emit Minted(msg.sender, initialTokenId + i);
        }
    }

    function migrateToken(uint256 id) public {
        require(migrationStarted == true, "Migration has not started");
        require(balanceOf(msg.sender) > 0, "Doesn't own the token");
        _burn(id);
        GalzVendingMachineImxInterface galzVendingMachineImxContract = GalzVendingMachineImxInterface(galzVendingMachineImxAddress);
        galzVendingMachineImxContract.mintTransfer(msg.sender);
    }

    function forceMigrateToken(uint256 id) public onlyOwner {
        require(balanceOf(msg.sender) > 0, "Doesn't own the token");
        _burn(id);
        GalzVendingMachineImxInterface galzVendingMachineImxContract = GalzVendingMachineImxInterface(galzVendingMachineImxAddress);
        galzVendingMachineImxContract.mintTransfer(msg.sender);
    }

    function getAmountMinted() view public returns(uint256) {
        uint256 amountMinted;
        amountMinted = nonce - 1;
        return amountMinted;
    }

    function setGalzVendingMachineImxContract(address contractAddress) public onlyOwner {
        galzVendingMachineImxAddress = contractAddress;
    }

    function toggleMigration() public onlyOwner {
        migrationStarted = !migrationStarted;
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
		uint256 tokenCount = balanceOf(_owner);
		if (tokenCount == 0) return new uint256[](0);
		else {
			uint256[] memory result = new uint256[](tokenCount);
			uint256 index;
			for (index = 0; index < tokenCount; index++) {
				result[index] = tokenOfOwnerByIndex(_owner, index);
			}
			return result;
		}
	}

	function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}