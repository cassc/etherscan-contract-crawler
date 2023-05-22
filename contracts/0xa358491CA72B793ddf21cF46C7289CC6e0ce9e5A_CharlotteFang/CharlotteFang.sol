/**
 *Submitted for verification at Etherscan.io on 2023-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract CharlotteFang is Ownable, ERC20 {
    IERC721[] public whitelistedCollections;
    
    IERC721 milady = IERC721(0x5Af0D9827E0c53E4799BB226655A1de152A425a5); // Milady
    IERC721 remilio = IERC721(0xD3D9ddd0CF0A5F0BFB8f7fcEAe075DF687eAEBaB); // Remilio
    IERC721 radbro = IERC721(0xABCDB5710B88f456fED1e99025379e2969F29610); // Radbro
    IERC721 pixelady = IERC721(0x8Fc0D90f2C45a5e7f94904075c952e0943CFCCfd); // Pixelady Maker
    IERC721 schizoposter = IERC721(0xBfE47D6D4090940D1c7a0066B63d23875E3e2Ac5); // SchizoPoster
    IERC721 meowlady1 = IERC721(0x441121dF09c8C7F545A9444aB554Ce640B566C4D); // Meowlady Maker
    IERC721 meowlady2 = IERC721(0xE5879aD3A66dd0a654DFd3A78FC6F720B05745F6); // Meowlady Maker 2
    IERC721 banner = IERC721(0x1352149Cd78D686043B504e7e7D96C5946b0C39c); // banners
    IERC721 ascii = IERC721(0x7BCF14419DEeF9eb466BeEFA75cF294BcA65D985); // Ascii Milady
    IERC721 vip = IERC721(0xFed18c828277E3bD8610F9BAE432e65A651706F7); // Very Internet Person
    IERC721 columbia = IERC721(0xED37c99f3000D751c460c5e386F02a6dE7581407); // Milady Columbia
    IERC721 heisei = IERC721(0x2D471c659682E92c79261124B5357Ae90Ff68dEa); // Heisei Milady Maker
    IERC721 milaidy = IERC721(0x0D8A3359182DCa59CCAF36F5c6C6008b83ceB4A6); // milAIdy maker
    IERC721 streets = IERC721(0x94Fe1D5DE3A4208C7411AE21968e044AbC17be48); // Streets of Milady
    IERC721 oekaki = IERC721(0x8f7a232aF2347CC5C9C3A245C2f163D248178eaa); // Oekaki Maker
    IERC721 ghiblady = IERC721(0x186E74aD45bF81fb3712e9657560f8f6361cbBef); // Ghiblady Maker
    IERC721 bonkler = IERC721(0xF421391011Dc77c0C2489d384C26e915Efd9e2C5); // Bonkler
    IERC721 bitch = IERC721(0x8A45Fb65311aC8434AaD5b8a93D1EbA6Ac4e813b); // Milady that BITCH
    IERC721 milaidys = IERC721(0x499De9CF6465c050aE116Afcbf9105e1d7259cb7); // milAIdys
    IERC721 miaura = IERC721(0x3a007aFA2dFF13C9DC5020acAE1bCb502d4312e2); // spring miaura
    IERC721 aura = IERC721(0x2fC722C1c77170A61F17962CC4D039692f033b43); // milady aura
    IERC721 petz = IERC721(0xc62E3fd5B02618f90dD07d1E478963038fA9089c); // milady aura petz
    IERC721 rock = IERC721(0x06078f22055CfB23193882879FD478471C8B4a03); // milady x etherrrock
    IERC721 pxrad = IERC721(0xb2619D1aEd8390aF6d7056B0D312557d3D4D419a); // pixelady maker radbro
    IERC721 pxbc = IERC721(0x4D40C64A8E41aC96b85eE557A434410672221750); // pixelady maker bc
    IERC721 pxwot = IERC721(0xcDDe7902fD9D8b2F142F39b11A6F30e213D00964); // pixelady maker wotlik
    IERC721 station = IERC721(0xe03480E9196003D9b4106C56595A1429F7D00f87); // miladystation
    IERC721 mifairy = IERC721(0x67B5eE6e29a4230177Dda07AD7848e42d89cF9a0); // mifairy maker
    IERC721 malily = IERC721(0x71481a928c24c32E4D9a4394FAb3168A3A1Cfd11); // water malilys
    IERC721 cig = IERC721(0xEEd41d06AE195CA8f5CaCACE4cd691EE75F0683f); // cigawrette packs
    IERC721 sadbro = IERC721(0x55241fF1f5877CFCA6b3E6CE2fcE30183eA2436A); // sadbros95
    IERC721 rave = IERC721(0x880a965fAe95f72fe3a3C8e87ED2c9478C8e0a29); // miladyrave
    IERC721 matrix = IERC721(0x4246200d62072Cf8836F1062A115927555B9C497); // matrix milady
    IERC721 remem = IERC721(0xc284B5407f2409bc43F202F29adA9E41566aF748); // remembrance banners
    IERC721 zlady = IERC721(0xd5e0b0F0Ac7c014A1bE55dE2D9De90cD2483d465); // zlady maker
    IERC721 r3dbro = IERC721(0x392C4a12044c7990f9FE66Ca9F119b1DF83f24AD); // r3dbro
    IERC721 schizopop = IERC721(0xB40e89D0A90d6A51E0Bd27040144cfcE51C9bC2d); // schizopops
    IERC721 janklerz = IERC721(0xEB3B0Ac9E4829a92E964e723EfDa9104ce0dE5Ec); // Janklerz
    IERC721 god = IERC721(0x285EA754D9418073cC87994F1De143f918551390); // Gods Remix
    IERC721 juice = IERC721(0xdc71c729e6aDf29FD1dbfd1D79e3e7558271a177); // strawberry juice
    IERC721 reptil = IERC721(0xC8FFC4E673fE7aa80E46c5d1Bde0fBe746B71341); // reptilianbabies
    IERC721 bored = IERC721(0xafe12842e3703a3cC3A71d9463389b1bF2c5BC1C); // bored milady maker
    IERC721 sonora = IERC721(0x9a051C1794C2f0ED9518Fcb68973DA84f756e29E); // Sonora Maker
    IERC721 mfer = IERC721(0x07e8D4A25D36D7259879337A923170453944614F); // milady mfers

    constructor() ERC20("Black Hearted Cyber Baby Angel Token", "MIYA") {
        _mint(msg.sender, 10000000 * 10 ** 18); // 10,000,000 MIYA
    }

    function pushToWhitelist(IERC721 _deriv) external onlyOwner {
        whitelistedCollections.push(_deriv);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        require(amount >= 0, "There is an overflow idk this check is here just bc i need to use amount");
        require(_whitelistedForTrading(from, to), "You do not own any approved Miya NFTs");
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

    function _whitelistedForTrading(address from, address to) internal view returns (bool) {

        if (from == owner() || to == owner()) {
            return true;
        }
        if (milady.balanceOf(from) > 0 || milady.balanceOf(to) > 0) {
            return true;
        }
        if (schizoposter.balanceOf(from) > 0 || schizoposter.balanceOf(to) > 0) {
            return true;
        }
        if (pixelady.balanceOf(from) > 0 || pixelady.balanceOf(to) > 0) {
            return true;
        }
        if (ascii.balanceOf(from) > 0 || ascii.balanceOf(to) > 0) {
            return true;
        }
        if (reptil.balanceOf(from) > 0 || reptil.balanceOf(to) > 0) {
            return true;
        }
        if (janklerz.balanceOf(from) > 0 || janklerz.balanceOf(to) > 0) {
            return true;
        }
        if (mfer.balanceOf(from) > 0 || mfer.balanceOf(to) > 0) {
            return true;
        }
        if (bored.balanceOf(from) > 0 || bored.balanceOf(to) > 0) {
            return true;
        }
        if (streets.balanceOf(from) > 0 || streets.balanceOf(to) > 0) {
            return true;
        }
        if (radbro.balanceOf(from) > 0 || radbro.balanceOf(to) > 0) {
            return true;
        }
        if (columbia.balanceOf(from) > 0 || columbia.balanceOf(to) > 0) {
            return true;
        }
        if (vip.balanceOf(from) > 0 || vip.balanceOf(to) > 0) {
            return true;
        }
        if (god.balanceOf(from) > 0 || god.balanceOf(to) > 0) {
            return true;
        }
        if (station.balanceOf(from) > 0 || station.balanceOf(to) > 0) {
            return true;
        }
        if (mifairy.balanceOf(from) > 0 || mifairy.balanceOf(to) > 0) {
            return true;
        }
        if (heisei.balanceOf(from) > 0 || heisei.balanceOf(to) > 0) {
            return true;
        }
        if (sadbro.balanceOf(from) > 0 || sadbro.balanceOf(to) > 0) {
            return true;
        }
        if (milaidy.balanceOf(from) > 0 || milaidy.balanceOf(to) > 0) {
            return true;
        }
        if (meowlady1.balanceOf(from) > 0 || meowlady1.balanceOf(to) > 0) {
            return true;
        }
        if (miaura.balanceOf(from) > 0 || miaura.balanceOf(to) > 0) {
            return true;
        }
        if (r3dbro.balanceOf(from) > 0 || r3dbro.balanceOf(to) > 0) {
            return true;
        }
        if (oekaki.balanceOf(from) > 0 || oekaki.balanceOf(to) > 0) {
            return true;
        }
        if (ghiblady.balanceOf(from) > 0 || ghiblady.balanceOf(to) > 0) {
            return true;
        }
        if (bitch.balanceOf(from) > 0 || bitch.balanceOf(to) > 0) {
            return true;
        }
        if (milaidys.balanceOf(from) > 0 || milaidys.balanceOf(to) > 0) {
            return true;
        }
        if (sonora.balanceOf(from) > 0 || sonora.balanceOf(to) > 0) {
            return true;
        }
        if (malily.balanceOf(from) > 0 || malily.balanceOf(to) > 0) {
            return true;
        }
        if (cig.balanceOf(from) > 0 || cig.balanceOf(to) > 0) {
            return true;
        }
        if (rave.balanceOf(from) > 0 || rave.balanceOf(to) > 0) {
            return true;
        }
        if (matrix.balanceOf(from) > 0 || matrix.balanceOf(to) > 0) {
            return true;
        }
        if (remem.balanceOf(from) > 0 || remem.balanceOf(to) > 0) {
            return true;
        }
        if (aura.balanceOf(from) > 0 || aura.balanceOf(to) > 0) {
            return true;
        }
        if (petz.balanceOf(from) > 0 || petz.balanceOf(to) > 0) {
            return true;
        }
        if (rock.balanceOf(from) > 0 || rock.balanceOf(to) > 0) {
            return true;
        }
        if (pxrad.balanceOf(from) > 0 || pxrad.balanceOf(to) > 0) {
            return true;
        }
        if (juice.balanceOf(from) > 0 || juice.balanceOf(to) > 0) {
            return true;
        }
        if (pxbc.balanceOf(from) > 0 || pxbc.balanceOf(to) > 0) {
            return true;
        }
        if (pxwot.balanceOf(from) > 0 || pxwot.balanceOf(to) > 0) {
            return true;
        }
        if (zlady.balanceOf(from) > 0 || zlady.balanceOf(to) > 0) {
            return true;
        }
        if (meowlady2.balanceOf(from) > 0 || meowlady2.balanceOf(to) > 0) {
            return true;
        }
        if (schizopop.balanceOf(from) > 0 || schizopop.balanceOf(to) > 0) {
            return true;
        }
        if (remilio.balanceOf(from) > 0 || remilio.balanceOf(to) > 0) {
            return true;
        }
        if (banner.balanceOf(from) > 0 || banner.balanceOf(to) > 0) {
            return true;
        }
        if (bonkler.balanceOf(from) > 0 || bonkler.balanceOf(to) > 0) {
            return true;
        }
        for (uint256 i = 0; i < whitelistedCollections.length; i++) {
            if (whitelistedCollections[i].balanceOf(from) > 0 || whitelistedCollections[i].balanceOf(to) > 0) {
                return true;
            }
        }
        return false;
    }
}