//           _____                    _____                    _____                    _____
//          /\    \                  /\    \                  /\    \                  /\    \
//         /::\    \                /::\    \                /::\    \                /::\    \
//        /::::\    \              /::::\    \               \:::\    \              /::::\    \
//       /::::::\    \            /::::::\    \               \:::\    \            /::::::\    \
//      /:::/\:::\    \          /:::/\:::\    \               \:::\    \          /:::/\:::\    \
//     /:::/__\:::\    \        /:::/__\:::\    \               \:::\    \        /:::/  \:::\    \
//    /::::\   \:::\    \      /::::\   \:::\    \              /::::\    \      /:::/    \:::\    \
//   /::::::\   \:::\    \    /::::::\   \:::\    \    ____    /::::::\    \    /:::/    / \:::\    \
//  /:::/\:::\   \:::\    \  /:::/\:::\   \:::\____\  /\   \  /:::/\:::\    \  /:::/    /   \:::\    \
// /:::/__\:::\   \:::\____\/:::/  \:::\   \:::|    |/::\   \/:::/  \:::\____\/:::/____/     \:::\____\
// \:::\   \:::\   \::/    /\::/    \:::\  /:::|____|\:::\  /:::/    \::/    /\:::\    \      \::/    /
//  \:::\   \:::\   \/____/  \/_____/\:::\/:::/    /  \:::\/:::/    / \/____/  \:::\    \      \/____/
//   \:::\   \:::\    \               \::::::/    /    \::::::/    /            \:::\    \
//    \:::\   \:::\____\               \::::/    /      \::::/____/              \:::\    \
//     \:::\   \::/    /                \::/____/        \:::\    \               \:::\    \
//      \:::\   \/____/                  ~~               \:::\    \               \:::\    \
//       \:::\    \                                        \:::\    \               \:::\    \
//        \:::\____\                                        \:::\____\               \:::\____\
//         \::/    /                                         \::/    /                \::/    /
//          \/____/                                           \/____/                  \/____/
//
//
//
//
// $Epic Token
// Website: https://epictoken.vip
// Telegram: https://t.me/EpictokenVIP
// Twitter: https://twitter.com/EpicToken_vip
//
// This Launch is SAFU certified by https://hypelaunchpad.vip

pragma solidity ^0.8.4;

contract Epic is ERC20, ReentrancyGuard, AccessControl, Ownable, Taxable {
    // Used for sending 5% sell tax the first 24 hours
    address taxWallet = 0x6bbb6b479E4A87523ff6Ca974e4E90F72582E248;

    // Total max supply set at 10 Billion
    uint256 maxSupply = 10_000_000_000 * (10 ** decimals());

    bytes32 public constant NOT_TAXED_FROM = keccak256("NOT_TAXED_FROM");
    bytes32 public constant NOT_TAXED_TO = keccak256("NOT_TAXED_TO");
    bytes32 public constant ALWAYS_TAXED_FROM = keccak256("ALWAYS_TAXED_FROM");
    bytes32 public constant ALWAYS_TAXED_TO = keccak256("ALWAYS_TAXED_TO");

    constructor()
        ERC20("EpicToken.vip", "EPIC")
        Taxable(true, 500, 1500, 25, taxWallet)
    {
        // Access control for tax
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(NOT_TAXED_FROM, msg.sender);
        _grantRole(NOT_TAXED_TO, msg.sender);
        _grantRole(NOT_TAXED_FROM, address(this));
        _grantRole(NOT_TAXED_TO, address(this));

        // Predefined Wallets
        address burnWallet = 0x000000000000000000000000000000000000dEaD;
        address marketingWallet = 0x3e9f058b7122c4D5F881692f12B4e0EC30029E86;
        address cexWallet = 0x09C01EC7A6cC049d43A1CB32293beCBe43FbB261;

        _mint(burnWallet, (maxSupply * 25) / 100); // 25%
        _mint(marketingWallet, (maxSupply * 20) / 100); // 20%
        _mint(cexWallet, (maxSupply * 10) / 100); // 10%

        // Mint to deployer to be used for Uniswap
        _mint(msg.sender, (maxSupply * 244) / 1000); // 24,4%
    }

    function enableTax() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _taxon();
    }

    function disableTax() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _taxoff();
    }

    function updateTax(uint newtax) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _updatetax(newtax);
    }

    function updateTaxDestination(
        address newdestination
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _updatetaxdestination(newdestination);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20) nonReentrant {
        if (hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            super._transfer(from, to, amount);
        } else {
            if (
                (hasRole(NOT_TAXED_FROM, from) ||
                    hasRole(NOT_TAXED_TO, to) ||
                    !taxed()) &&
                !hasRole(ALWAYS_TAXED_FROM, from) &&
                !hasRole(ALWAYS_TAXED_TO, to)
            ) {
                super._transfer(from, to, amount);
            } else {
                require(
                    balanceOf(from) >= amount,
                    "Error: transfer amount exceeds balance"
                );
                super._transfer(
                    from,
                    taxdestination(),
                    (amount * thetax()) / 10000
                );
                super._transfer(
                    from,
                    to,
                    (amount * (10000 - thetax())) / 10000
                );
            }
        }
    }

    // 20,6% of total supply
    function airdropPresale() external onlyOwner {
        _mint(0x4C86D72e7CBff8E3e23B7d423F69A2c95BD025A5, (maxSupply * 16) / 1000);
        _mint(0x5458892De03bECb936f4E7aF55065C48E926a69f, (maxSupply * 12) / 1000);
        _mint(0x6278346671FEE03A4EF7D7d85a2B76000ED9E448, (maxSupply * 10) / 1000);
        _mint(0x5D217e541a425Eb173837b60873DcbbDA2000911, (maxSupply * 6) / 1000);
        _mint(0xF985f9097d711049824d888f696Cc1A47ef9F9cD, (maxSupply * 8) / 1000);
        _mint(0x5Ec1a1Ed430164EC715F5bBcBDBda8a743c39f77, (maxSupply * 2) / 1000);
        _mint(0x39c00a780cB1a778FBB0A169699652A4816d5E8C, (maxSupply * 4) / 1000);
        _mint(0xEa145Da3952694e143e7418D80B548466b4701BB, (maxSupply * 4) / 1000);
        _mint(0xd3FBd7d5f7f82B2B390f3C9d2Ee45cF453B826dE, (maxSupply * 2) / 1000);
        _mint(0xD2BaEE8234fD8A2669AF4eDe19AeBcEF835A7418, (maxSupply * 4) / 1000);
        _mint(0x0Dc9bfe243dC97b9ef6b0c8aF67b8F3FA3Eec303, (maxSupply * 4) / 1000);
        _mint(0xbD0586BBfF3506A4cAB24Eb456675CE3E52fE04e, (maxSupply * 4) / 1000);
        _mint(0x6758692AA8498C1CDA41A24aFd6dDdD20c37E136, (maxSupply * 4) / 1000);
        _mint(0x8503a12879B7c551FACeE7BDba8Ed9CDac17465B, (maxSupply * 2) / 1000);
        _mint(0xFE288CCEdF5536455e48bBA3939e306Dfb09a763, (maxSupply * 2) / 1000);
        _mint(0x299C0d67FF73FDd5148b8d5947D819962eC16Ed2, (maxSupply * 4) / 1000);
        _mint(0x082D7B610cBD9B718a24Df843eb40ad0A7EAD1B3, (maxSupply * 2) / 1000);
        _mint(0xdE8A8AA1D9E5f076aBDa972b8396472e5c9a54cC, (maxSupply * 2) / 1000);
        _mint(0x217ACda0590147A9E1015Aab869d3962fc21515c, (maxSupply * 2) / 1000);
        _mint(0xBA90d84be49f470d7b8C0177aB8a151E6e11C145, (maxSupply * 2) / 1000);
        _mint(0xe41056EEBF24283717B540fde7B3Fcd2D53F27bE, (maxSupply * 4) / 1000);
        _mint(0xBFCa48363a5e60592247BF5878Ab4aab8dD708Dd, (maxSupply * 4) / 1000);
        _mint(0xA6b8e148835B79b5aE186e392E32D97b645d7F59, (maxSupply * 2) / 1000);
        _mint(0x5Fed97BbE88f5Ba24F61FF0308c46c4A56ec900B, (maxSupply * 4) / 1000);
        _mint(0xF36699e6F15295e1549576AeA00986C06996466E, (maxSupply * 6) / 1000);
        _mint(0xB068A8DA400B3E3D3bf7CE95179846c90ae7B14c, (maxSupply * 4) / 1000);
        _mint(0xC334f5b47B7351cD663E4896286402d83a9DC5Ad, (maxSupply * 4) / 1000);
        _mint(0xfEdc79fF731e973e02707fac55e01AF4BeEcBba6, (maxSupply * 4) / 1000);
        _mint(0x9b16BCa1F7a9Fda3A2d8F5C7E869c7567f450aAf, (maxSupply * 2) / 1000);
        _mint(0xb5bcAb511dbcCf9D304d6964072A824F3910a56b, (maxSupply * 2) / 1000);
        _mint(0xcd464768906Cb1DF8C69594CA4A72ea7D5C98f9b, (maxSupply * 2) / 1000);
        _mint(0x809B4Df147E0a8FD624753d07e8018CA13980f6E, (maxSupply * 4) / 1000);
        _mint(0x6f6e376f00bfEb1f35494B3Fe84CfbC1816eCDA5, (maxSupply * 2) / 1000);
        _mint(0x8ba807B7Ba7af0D5e0cD07a061B4e2BB4a06059b, (maxSupply * 4) / 1000);
        _mint(0xAcAAF794B16B75f8fad79Cf6DB70761Dd18662f1, (maxSupply * 4) / 1000);
        _mint(0x2B17AD81b6eDeDb392852f60888Eb7F3a613eBeD, (maxSupply * 6) / 1000);
        _mint(0x363c3116D796ED45871f2855111cAfA44788ba0B, (maxSupply * 2) / 1000);
        _mint(0x4435a1bD794b57C950ffD854D19eA408D93ba11e, (maxSupply * 2) / 1000);
        _mint(0x673E9D3D82938a7a1d148aE426c3FC7553120E6E, (maxSupply * 4) / 1000);
        _mint(0xE69dF133Fb7CB2eFebD9F63B9D48262BC542fA5a, (maxSupply * 2) / 1000);
        _mint(0x5A0803b26a2f5be431789f95b22fa7419307e641, (maxSupply * 4) / 1000);
        _mint(0xC26b80C8A335bF9F33E28d341ea2693aa1bE3d71, (maxSupply * 2) / 1000);
        _mint(0x874541c55a9E78523A27949F5B64E6fe7f1d337c, (maxSupply * 2) / 1000);
        _mint(0xA072496Bb3494E9051bfb6960d71f87bB7614DbC, (maxSupply * 2) / 1000);
        _mint(0x5f34FB36e7943a2ed6052F903D3Bc8011105e6a4, (maxSupply * 2) / 1000);
        _mint(0xB7B11a422D7649910F8FBCAceB8EEDB4415f4D61, (maxSupply * 8) / 1000);
        _mint(0x879C405922ffb8251bDDf7dF06E02A58B10837f3, (maxSupply * 8) / 1000);
        _mint(0x11545B6fF6Fb442Bd48a53F04Ead36BFa9934CF4, (maxSupply * 2) / 1000);
        _mint(0x282E71555501A29113238D3A4938ecEf67c59dCe, (maxSupply * 8) / 1000);
        _mint(0x8b2422D32546d65DB67cd374deFB1bba52EA929E, (maxSupply * 2) / 1000);
        _mint(0x881593A2366c4Ac004F50a3a8663b441C7aeE332, (maxSupply * 2) / 1000);
    }
}

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Taxable.sol";