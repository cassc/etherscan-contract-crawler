// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

contract NoOwnerFixedNoMintNoBurnNoPause is ERC20 {

    uint8 immutable s_decimals;

    constructor(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 _decimals
                ) ERC20(name, symbol) {
         s_decimals =  _decimals; 
        _mint(owner, initialSupply * (10 ** decimals()));
    }

    function decimals() public view override returns (uint8) {
        return s_decimals;
    }
}



contract FactoryNoOwnerFixedNoMintNoBurnNoPause{
    function create(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals) public returns (NoOwnerFixedNoMintNoBurnNoPause) {
        return new NoOwnerFixedNoMintNoBurnNoPause(name,symbol,initialSupply,owner,decimals);
    }
}


contract NoOwnerFixedNoMintCanBurnNoPause is ERC20Burnable {

    uint8 immutable s_decimals;

    constructor(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 _decimals
                ) ERC20(name, symbol){
                    s_decimals =  _decimals; 
                    _mint(owner, initialSupply * (10 ** decimals()));
                }

    function decimals() public view override returns (uint8) {
        return s_decimals;
    }            


}

contract FactoryNoOwnerFixedNoMintCanBurnNoPause{
    function create(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals) public returns (NoOwnerFixedNoMintCanBurnNoPause) {
        return new NoOwnerFixedNoMintCanBurnNoPause(name,symbol,initialSupply,owner,decimals);
    }
}

contract OwnedFixedNoMintNoBurnNoPause is ERC20, Ownable {

    uint8 immutable s_decimals;

    constructor(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 _decimals
                ) ERC20(name, symbol) {
                    transferOwnership(owner);
                    s_decimals =  _decimals; 
                    _mint(owner, initialSupply * (10 ** decimals()));
                }

    function decimals() public view override returns (uint8) {
        return s_decimals;
    }            


}

contract FactoryOwnedFixedNoMintNoBurnNoPause{
    function create(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals) public returns (OwnedFixedNoMintNoBurnNoPause) {
        return new OwnedFixedNoMintNoBurnNoPause(name,symbol,initialSupply,owner,decimals);
    }
}


contract OwnedFixedNoMintCanBurnNoPause is ERC20, Ownable, ERC20Burnable {

    uint8 immutable s_decimals;

    constructor(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 _decimals
                ) ERC20(name, symbol) {
                    transferOwnership(owner);
                    s_decimals =  _decimals; 
                    _mint(owner, initialSupply * (10 ** decimals()));
                }

    function decimals() public view override returns (uint8) {
        return s_decimals;
    }            


}

contract FactoryOwnedFixedNoMintCanBurnNoPause{
    function create(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals) public returns (OwnedFixedNoMintCanBurnNoPause) {
        return new OwnedFixedNoMintCanBurnNoPause(name,symbol,initialSupply,owner,decimals);
    }
}


contract OwnedFixedNoMintNoBurnCanPause is ERC20, Pausable, Ownable {
    
    uint8 immutable s_decimals;

    constructor(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 _decimals
                ) ERC20(name, symbol) {
                    transferOwnership(owner);
                    s_decimals =  _decimals; 
                    _mint(owner, initialSupply * (10 ** decimals()));
                }

    function decimals() public view override returns (uint8) {
        return s_decimals;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}

contract FactoryOwnedFixedNoMintNoBurnCanPause{
    function create(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals) public returns (OwnedFixedNoMintNoBurnCanPause) {
        return new OwnedFixedNoMintNoBurnCanPause(name,symbol,initialSupply,owner,decimals);
    }
}



contract OwnedFixedNoMintCanBurnCanPause is ERC20, Pausable, Ownable, ERC20Burnable {
    
    uint8 immutable s_decimals;

    constructor(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 _decimals
                ) ERC20(name, symbol) {
                    transferOwnership(owner);
                    s_decimals =  _decimals; 
                    _mint(owner, initialSupply * (10 ** decimals()));
                }

    function decimals() public view override returns (uint8) {
        return s_decimals;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}

contract FactoryOwnedFixedNoMintCanBurnCanPause{
    function create(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals) public returns (OwnedFixedNoMintCanBurnCanPause) {
        return new OwnedFixedNoMintCanBurnCanPause(name,symbol,initialSupply,owner,decimals);
    }
}

contract OwnedUnlimitCanMintCanBurnCanPause is ERC20, Pausable, Ownable, ERC20Burnable {
    
    uint8 immutable s_decimals;

    constructor(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 _decimals
                ) ERC20(name, symbol) {
                    transferOwnership(owner);
                    s_decimals =  _decimals; 
                    _mint(owner, initialSupply * (10 ** decimals()));
                }

    function decimals() public view override returns (uint8) {
        return s_decimals;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}



contract FactoryOwnedUnlimitCanMintCanBurnCanPause{
    function create(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals) public returns (OwnedUnlimitCanMintCanBurnCanPause) {
        return new OwnedUnlimitCanMintCanBurnCanPause(name,symbol,initialSupply,owner,decimals);
    }
}









contract OwnedUnlimitCanMintNoBurnCanPause is ERC20, Pausable, Ownable {
    
    uint8 immutable s_decimals;

    constructor(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 _decimals
                ) ERC20(name, symbol) {
                    transferOwnership(owner);
                    s_decimals =  _decimals; 
                    _mint(owner, initialSupply * (10 ** decimals()));
                }

    function decimals() public view override returns (uint8) {
        return s_decimals;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}

contract FactoryOwnedUnlimitCanMintNoBurnCanPause{
    function create(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals) public returns (OwnedUnlimitCanMintNoBurnCanPause) {
        return new OwnedUnlimitCanMintNoBurnCanPause(name,symbol,initialSupply,owner,decimals);
    }
}





contract OwnedUnlimitCanMintNoBurnNoPause is ERC20, Ownable {
    
    uint8 immutable s_decimals;

    constructor(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 _decimals
                ) ERC20(name, symbol) {
                    transferOwnership(owner);
                    s_decimals =  _decimals; 
                    _mint(owner, initialSupply * (10 ** decimals()));
                }

    function decimals() public view override returns (uint8) {
        return s_decimals;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }


}

contract FactoryOwnedUnlimitCanMintNoBurnNoPause{
    function create(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals) public returns (OwnedUnlimitCanMintNoBurnNoPause) {
        return new OwnedUnlimitCanMintNoBurnNoPause(name,symbol,initialSupply,owner,decimals);
    }
}






contract OwnedUnlimitCanMintCanBurnNoPause is ERC20, Ownable, ERC20Burnable {
    
    uint8 immutable s_decimals;

    constructor(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 _decimals
                ) ERC20(name, symbol) {
                    transferOwnership(owner);
                    s_decimals =  _decimals; 
                    _mint(owner, initialSupply * (10 ** decimals()));
                }

    function decimals() public view override returns (uint8) {
        return s_decimals;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }


}

contract FactoryOwnedUnlimitCanMintCanBurnNoPause{
    function create(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals) public returns (OwnedUnlimitCanMintCanBurnNoPause) {
        return new OwnedUnlimitCanMintCanBurnNoPause(name,symbol,initialSupply,owner,decimals);
    }
}




contract OwnedCappedCanMintCanBurnCanPause is ERC20, Pausable, Ownable, ERC20Burnable {
    
    uint8 immutable s_decimals;
    uint256 private immutable s_cap;

    constructor(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 _decimals, uint256 _cap
                ) ERC20(name, symbol) {
                    transferOwnership(owner);
                    s_decimals =  _decimals;
                    require(_cap > 0, "ERC20Capped: cap is 0");
                    s_cap = _cap;
                    _mint(owner, initialSupply * (10 ** decimals()));
                }

                            
    function cap() public view returns (uint256) {
        return s_cap;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        _mint(to, amount);
    }
    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}

contract FactoryOwnedCappedCanMintCanBurnCanPause{
    function create(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals, uint256 _cap) public returns (OwnedCappedCanMintCanBurnCanPause) {
        return new OwnedCappedCanMintCanBurnCanPause(name,symbol,initialSupply,owner,decimals,_cap);
    }
}



contract OwnedCappedCanMintNoBurnCanPause is ERC20, Pausable, Ownable {
    
    uint8 immutable s_decimals;
    uint256 private immutable s_cap;

    constructor(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 _decimals, uint256 _cap
                ) ERC20(name, symbol) {
                    transferOwnership(owner);
                    s_decimals =  _decimals;
                    require(_cap > 0, "ERC20Capped: cap is 0");
                    s_cap = _cap;
                    _mint(owner, initialSupply * (10 ** decimals()));
                }

                            
    function cap() public view returns (uint256) {
        return s_cap;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        _mint(to, amount);
    }
    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}

contract FactoryOwnedCappedCanMintNoBurnCanPause{
    function create(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals, uint256 _cap) public returns (OwnedCappedCanMintNoBurnCanPause) {
        return new OwnedCappedCanMintNoBurnCanPause(name,symbol,initialSupply,owner,decimals,_cap);
    }
}


contract OwnedCappedCanMintCanBurnNoPause is ERC20, Ownable, ERC20Burnable {
    
    uint8 immutable s_decimals;
    uint256 private immutable s_cap;

    constructor(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 _decimals, uint256 _cap
                ) ERC20(name, symbol) {
                    transferOwnership(owner);
                    s_decimals =  _decimals;
                    require(_cap > 0, "ERC20Capped: cap is 0");
                    s_cap = _cap;
                    _mint(owner, initialSupply * (10 ** decimals()));
                }

                            
    function cap() public view returns (uint256) {
        return s_cap;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        _mint(to, amount);
    }
    
}

contract FactoryOwnedCappedCanMintCanBurnNoPause{
    function create(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals, uint256 _cap) public returns (OwnedCappedCanMintCanBurnNoPause) {
        return new OwnedCappedCanMintCanBurnNoPause(name,symbol,initialSupply,owner,decimals,_cap);
    }
}







contract OwnedCappedCanMintNoBurnNoPause is ERC20, Ownable {
    
    uint8 immutable s_decimals;
    uint256 private immutable s_cap;

    constructor(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 _decimals, uint256 _cap
                ) ERC20(name, symbol) {
                    transferOwnership(owner);
                    s_decimals =  _decimals;
                    require(_cap > 0, "ERC20Capped: cap is 0");
                    s_cap = _cap;
                    _mint(owner, initialSupply * (10 ** decimals()));
                }

                            
    function cap() public view returns (uint256) {
        return s_cap;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        _mint(to, amount);
    }
    
}

contract FactoryOwnedCappedCanMintNoBurnNoPause{
    function create(string memory name, string memory symbol, uint256 initialSupply, address owner, uint8 decimals, uint256 _cap) public returns (OwnedCappedCanMintNoBurnNoPause) {
        return new OwnedCappedCanMintNoBurnNoPause(name,symbol,initialSupply,owner,decimals,_cap);
    }
}