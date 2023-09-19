/*

$$\       $$\      $$\  $$$$$$\   $$$$$$\  
$$ |      $$$\    $$$ |$$  __$$\ $$  __$$\ 
$$ |      $$$$\  $$$$ |$$ /  $$ |$$ /  $$ |
$$ |      $$\$$\$$ $$ |$$$$$$$$ |$$ |  $$ |
$$ |      $$ \$$$  $$ |$$  __$$ |$$ |  $$ |
$$ |      $$ |\$  /$$ |$$ |  $$ |$$ |  $$ |
$$$$$$$$\ $$ | \_/ $$ |$$ |  $$ | $$$$$$  |
\________|\__|     \__|\__|  \__| \______/ 

https://t.me/AyyLmaoPortal
https://ayylmao.space
https://twitter.com/ayylmao_eth                                    

ayy lmao $LMAO (the “$LMAO token”)
 
DISCLAIMER: THIS TOKEN IS NOT A SECURITY
 
IMPORTANT: PLEASE READ THIS DISCLAIMER CAREFULLY BEFORE PROCEEDING WITH ANY PURCHASE OF THE $LMAO TOKEN. BY PURCHASING THE $LMAO TOKEN, YOU ACKNOWLEDGE THAT YOU HAVE READ THIS DISCLAIMER, UNDERSTAND IT, AND AGREE TO BE BOUND BY ITS TERMS.
 
1. NOT A SECURITY:
The $LMAO token is NOT a security by any definition of the term "security" as may be interpreted by the U.S. Securities and Exchange Commission (SEC). The $LMAO token does not qualify as a security under Section 2(a)(1) of the Securities Act of 1933 and Section 3(a)(10) of the Securities Exchange Act of 1934. The issuance and transfer of the $LMAO token have not been registered under these or any other securities laws, and therefore cannot and should not be considered as such.
 
2. NO INVESTMENT:
The purchase of the $LMAO token is not an investment. You acknowledge that you are not purchasing the $LMAO token with the expectation of earning a return or profit.
 
3. NO COMMON ENTERPRISE:
You acknowledge that there is no common enterprise between you, the issuer of the $LMAO token, or any other holder of the $LMAO token. The issuer of the $LMAO token is not responsible for and has no obligations towards the utility, value, or transferability of the $LMAO token.
 
4. NO EFFORTS OF OTHERS:
You acknowledge that any potential increase in the utility or value of the $LMAO token will not come solely from the efforts of others. You have no expectation that others will perform labor or undertake efforts that would result in a profit or increase in value for you.
 
5. COMPLETE UNDERSTANDING:
By purchasing the $LMAO token, you confirm that you fully understand that the $LMAO token is not a security, not an investment, and that there is no common enterprise between you and the issuer or any other holder of the $LMAO token.
 
6. BINDING AGREEMENT:
By purchasing the $LMAO token, you agree to these terms and acknowledge that you are not purchasing a security, and you relinquish any and all rights to participate in, or make claims based on, securities laws, including but not limited to any sort of legal actions, claims, suits, or complaints.
 
7. LEGAL JURISDICTION:
This disclaimer and the purchase of the $LMAO token are governed by the laws of the Republic of Malta.
 
8. INDEPENDENT LEGAL ADVICE:
You acknowledge that you have had the opportunity to seek independent legal advice before purchasing the $LMAO token and that either you have done so or you have voluntarily chosen not to.
 
9. RISK DISCLOSURE AND ASSUMPTION OF RISK:
You expressly acknowledge, understand, and agree that your purchase of the $LMAO token is inherently risky. Risks include, but are not limited to, market volatility, technological vulnerabilities, regulatory actions or inactions, and the potential for total and permanent loss of value. By purchasing the $LMAO token, you affirm that you fully understand and voluntarily assume these risks, and you agree that the issuer shall not be liable for any losses, direct or indirect, that result from your purchase or holding of the $LMAO token.
 
10. AFFIRMATIVE CONFIRMATION AND BINDING ACCEPTANCE:
By purchasing the $LMAO token, you expressly acknowledge and affirm that you have read, understood, and unconditionally agree to be bound by every term and condition set forth in this disclaimer, including but not limited to the risk disclosures, limitations of liability, and arbitration requirements. You also acknowledge that you have had the opportunity to seek independent legal advice prior to making this purchase. Your purchase of the $LMAO token constitutes irrevocable acceptance of, and agreement to, all such terms and conditions.
 
11. UPDATES AND AMENDMENTS:
The issuer reserves the right to modify this disclaimer at any time, and it is your responsibility to review it for any changes before purchasing the $LMAO token.
 
12. THIRD PARTIES: INDEMNIFICATION AGAINST CLAIMS:
By purchasing the $LMAO token, you acknowledge and agree that this disclaimer does not offer any assurances or protections with respect to third parties that may offer, promote, or trade the $LMAO token. You further agree to indemnify, defend, and hold harmless the issuer of the $LMAO token from and against all claims, damages, losses, and expenses (including but not limited to reasonable attorney fees) arising from or related to any promotions, representations, or activities conducted by third-party sellers, promoters, or traders of the $LMAO token. You acknowledge that the issuer is not liable for any statements made or actions taken by such third parties, including but not limited to claims related to the potential profitability of the $LMAO token.
 
13. WAIVER OF CLASS ACTIONS OR ARBITRATION CLAUSE:
You agree to settle any disputes through individual arbitration and waive your right to participate in any class-action lawsuits against the issuer.
 
14. SEVERABILITY:
If any provision of this disclaimer is deemed invalid or unenforceable, the remaining provisions will continue in full force and effect.
 
15. ENTIRE AGREEMENT:
This disclaimer constitutes the entire agreement between you and the issuer with respect to your purchase of the $LMAO token and supersedes all prior understandings, both oral and written.
                                            
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ayylmao is Ownable, ERC20 {
    error Transfer__Paused();
    error Unauthorized();
    error Zero__Address();
    error Max__Wallet__Size__Exceeded();
    error Max__Ten__Percent();

    string internal _name = "ayy lmao";
    string internal _symbol = "LMAO";
    uint256 internal _supply = 800813500000 * 10 ** 18;
    uint256 public maxWalletSize = (_supply * 3) / 100;

    uint256 public buyTaxPercentage = 9999 * 10 ** 16;
    uint256 public sellTaxPercentage = 9999 * 10 ** 16;

    bool ownershipRenounced;
    bool transferPaused;
    bool whaleProtection;
    address public marketplace;
    address public marketingWallet;
    address public governor;

    mapping(address => bool) public whitelist;

    modifier onlyGovernor() {
        if (msg.sender != governor) {
            revert Unauthorized();
        }
        _;
    }

    constructor(address _marketingWallet) ERC20(_name, _symbol) {
        if (_marketingWallet == address(0)) {
            revert Zero__Address();
        }
        _mint(msg.sender, _supply);
        marketingWallet = _marketingWallet;
        governor = msg.sender;
        whaleProtection = true;
    }

    function renounceOwnership() public virtual override onlyOwner {
        ownershipRenounced = true;
        if (transferPaused) {
            transferPaused = false;
        }
        super.renounceOwnership();
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (transferPaused) {
            revert Transfer__Paused();
        }

        if (sender == owner() && recipient == marketplace) {
            super._transfer(sender, recipient, amount);
        } else {
            if (!whitelist[sender] && !whitelist[recipient]) {
                uint256 taxPercentage = getTaxPercentage(sender, recipient);
                uint256 tax = (amount * taxPercentage) / 10 ** 20;
                uint256 amountAfterTax = amount - tax;
                if (whaleProtection) {
                    if (recipient != marketplace) {
                        if (
                            balanceOf(recipient) + amountAfterTax >
                            maxWalletSize
                        ) {
                            revert Max__Wallet__Size__Exceeded();
                        }
                    }
                }
                super._transfer(sender, recipient, amountAfterTax);
                super._transfer(sender, marketingWallet, tax);
            } else {
                super._transfer(sender, recipient, amount);
            }
        }
    }

    function getTaxPercentage(
        address sender,
        address recipient
    ) internal view returns (uint256 percentage) {
        if (sender == marketplace) {
            percentage = buyTaxPercentage;
        } else if (recipient == marketplace) {
            percentage = sellTaxPercentage;
        } else {
            percentage = 0;
        }
    }

    function setBuyTaxPercentage(
        uint256 _buyTaxPercentage
    ) external onlyGovernor {
        if (ownershipRenounced) {
            if (_buyTaxPercentage > 10 * 10 ** 18) {
                revert Max__Ten__Percent();
            }
        }
        buyTaxPercentage = _buyTaxPercentage;
    }

    function setSellTaxPercentage(
        uint256 _sellTaxPercentage
    ) external onlyGovernor {
        if (ownershipRenounced) {
            if (_sellTaxPercentage > 10 * 10 ** 18) {
                revert Max__Ten__Percent();
            }
        }
        sellTaxPercentage = _sellTaxPercentage;
    }

    function setMarketingWallet(
        address _marketingWallet
    ) external onlyGovernor {
        if (_marketingWallet == address(0)) {
            revert Zero__Address();
        }
        marketingWallet = _marketingWallet;
    }

    function setMarketplace(address _marketplace) external onlyGovernor {
        if (_marketplace == address(0)) {
            revert Zero__Address();
        }
        marketplace = _marketplace;
    }

    function pause() external onlyOwner {
        transferPaused = true;
    }

    function unPause() external onlyOwner {
        transferPaused = false;
    }

    function addToWhitelist(address[] memory wallets) external onlyGovernor {
        for (uint256 i = 0; i < wallets.length; i++) {
            whitelist[wallets[i]] = true;
        }
    }

    function removeFromWhitelist(
        address[] memory wallets
    ) external onlyGovernor {
        for (uint256 i = 0; i < wallets.length; i++) {
            whitelist[wallets[i]] = false;
        }
    }

    function antiWhale(bool enabled) external onlyOwner {
        whaleProtection = enabled;
    }

    function isWhitelisted(address wallet) external view returns (bool) {
        return whitelist[wallet];
    }
}