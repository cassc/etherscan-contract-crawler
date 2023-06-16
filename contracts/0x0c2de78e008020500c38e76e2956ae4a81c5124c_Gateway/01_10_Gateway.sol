// SPDX-License-Identifier: AGPL-3.0

/*

 Used only by [swappin.gifts](https://swappin.gifts]) to accept payments in any token or native coin.
 We've designed this contract to be non-upgradable. Once the contract has been deployed to the blockchain, it will never change.
 This guarantee, as provided by the blockchain, together with the complete source code of the contract, will allow any party to verify the security properties and guarantees.
 By putting security and transparency first, we hope to pave the way for a more trustless and trustable ecosystem.
 Clara pacta, boni amici.


                                                             =;                                                                                                 
                                                            ;@f     `z.                                                                                         
                                                           [email protected]@o    *QR                                                                                          
                                                          [email protected]@@*`^[email protected]@~                                                                                          
                               `!vSjv*.                 [email protected]@@@%@@@@@B;;~~~:,,'`` `,.                                                                            
                           `^[email protected]@@}    :i      ``...';[email protected]@@@@@@@@@@@@@@@@@@@@@@@@QY;~'`                                                                         
                        :[email protected]@@@@@@Wi*[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@QNKa7<;,.     `                                                         
                      [email protected]@@@@@@@@@@@@@@@@@@@@@@DXUd&@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@Qm<`                                                         
                      [email protected]@@[email protected]@@@@@@@@@@@@@@@Qf;,`,[email protected]@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@NESE%@@@Q86}|~`                                                  
                       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]%[email protected]@@@[email protected]@@@@@@@@@@@@@QE=.                                              
                       [email protected]@b;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&hz?!^[email protected]@@@@@@@Q&#%[email protected]@@@@@@@@@@@@@@@@@@q*.                                           
                       '[email protected]@`[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@Qbj\r,``;fDQQQWE|;,~~~~,[email protected]@@@[email protected]@@@@@@@@@@@@@@@@@Bj+`                                       
                        '[email protected] |~`qf .~wbDDgWD%[email protected]@@@@@@@@@@@@@@@@@@@QWEL,7yjz+,   ,?7yXqUSc;.~?}[email protected]|=*s}yZShXqDDy?^'                                   
                         `[email protected]*    ~   ,[email protected]@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@[email protected]@@@@@@@Qw^Z6yc;   ,\i>~'[email protected]@@@@@@@@@W%D%j!                               
                           ^Q|      ;[email protected]@@@@QDk<@@@@@@@@@@@@@@@[email protected]@@@@@[email protected]@@@@@@Q*}@@@@@@@z`[email protected]@@@E,'|{XQQa=*[email protected]@@[email protected]@@@@@@@@@bAQQ^                             
                            `\i`  [email protected]@@@@DDQQ^[email protected]@@@@@[email protected]@@kT=vi^>[email protected]@@@@{@@@@@@Y``[email protected]@@@@@j ,@@@@@@@^:QgJ~~^^`'[email protected]@[email protected]@@@@@@@@@@[email protected]`                           
                               `;[email protected]@@@#[email protected]; [email protected]@@@@@@@P,Bi`[email protected]@{[email protected]@@@[email protected]@@@%i` [email protected]@@@87'`[email protected]@@@@@@@j [email protected]@@6,`:   `^[email protected]@@@@@@@@@@Q;                          
                              ,[email protected]@@@[email protected]`  ;@@@@@@@@@Qi  [email protected]+%[email protected]@@[email protected]#J_~<[email protected]%qX*[email protected]@@@@@@@Qi'}@@@@@Q ;Nx.   '`'r^':^|[email protected]@d;                        
                          `[email protected]@@@o^[email protected]: *@@@@@gSoLvEy   ?f\[email protected]@RLi5*''<aR8BNkjz^!yD%[email protected]@@@@@@7 '[email protected]@E``;[email protected]>~DNQQQNDdaLu\`                     
                        [email protected]@[email protected]@hsBhQI`[email protected]@@@@@@[email protected]@~     [email protected],     !R67^,     .\aEZs|!, 'iUg#%Ayz|;`[email protected]@@@@8 ;%}[email protected]@@[email protected]@@@@@@@@U|EK*`                  
                      ,[email protected]@@@;@#[email protected][email protected]@@%@@@@@j7QQf_ {    ;Dg6E%%Wq<      .r`        `,`       ~XE7^_,[email protected]@@@@@@@@, [email protected];j*[email protected]@[email protected]@@@@@@@@@@%[email protected];                 
                   ~*[email protected]@@@@@~^[email protected]' [email protected]@@@@@d}n8m~       `6D~:IQQs'                             '        .^[email protected]@@@Q%c  }@@Q.  `[email protected]@@@@@@@@@@@@@@;                
                  [email protected]'@@@@@Q^[email protected]    `~;;^=7T~          D\  DD!                                               ;xi?<*[email protected]@@@k j:  ~ugQQ#@@@@@@@@@@Q`               
                [email protected]@d*@@@QRxQ?                       .=  ^!                                                  `[email protected]@@@@@@^ [email protected]`XE+.\wc;;*[email protected]@@Q,              
               i} [email protected]@@w^gk8%m;                            `                                                       .;?vz|. `[email protected]@d`[email protected][email protected]@Qz}@@Q%DKDQE,            
             .K7 '[email protected]@@@'.QQ;L                                                                                      [email protected]@@@@,a^[email protected]@@[email protected]@@@@@@@K'           
            ~Q7 [email protected]@@@@L5#''                                                                                        [email protected]@@@@@@'[email protected]~ , ,[email protected]@[email protected]@@@@@@@@QI.         
           [email protected]#z;[email protected]@@@QDI~                                                                                              '~^in{\' [email protected]@;    [email protected]@@@@@@@@@@@o`       
          <[email protected]@@@@[email protected]:                                                                                                [email protected]@@#      ~U%[email protected]@@@@@@@@j       
         [email protected]~`@@[email protected]@!     .s.                                                                                           [email protected]@@@@@@`b. dj' >f|[email protected]@@@@@@`      
        <@i [email protected]@@u^[email protected]@^     ,Q~                                                                                               _\mDBq* 8#`[email protected]@z{@@NS,[email protected]@@@^      
       [email protected] ;@@@@@`[email protected]~   ^`[email protected]                                                                                               ^7;`    [email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@@B.     
       QQ``[email protected]@@@@[email protected]~  'E:[email protected]@.                                                                                                [email protected]@[email protected]@@@Q,'<Qy,@@@[email protected]@@@@@hQ6+`   
    *\`@< [email protected]@@@@@h8  ~d'[email protected]@a=                                                                                                  ;[email protected]@@@@@h!Q`.K.,#@[email protected]@@@@@@@@j    
    [email protected]@ ;@@@@@@AQa ~B'[email protected]@@^%  !                                                                                                '`!7jY^ [email protected]\  , `[email protected]@@@@@@@@@}   
    [email protected]@@;}@@@@@[email protected]!'Q;[email protected]`{,                                                                                                _%n^,,[email protected]@D   ' `[email protected]@@@@@@@@U   
    b%[email protected]@[email protected]@@[email protected]`Bj>qy{EjUQB|                                                                                                  ,[email protected]@@@@@@B ! Wy .;;[email protected]@@@@@@E   
   <@;[email protected]@@Az%*[email protected]`EQ`[email protected];[email protected];                                                                                                     [email protected]@@@@n D~%@[email protected],[email protected]@@@@a   
  :@Q,@@@@@Q;`[email protected]'[email protected] [email protected]@|  ;`                                                                                                     `\_'*ti~ [email protected]|@[email protected]@@[email protected]@R   
  #@a<@@@@@@@\!,,@@, [email protected]@^ ,                                                                                                        ;@Q{^;!}@@* [email protected]`@@[email protected]@@y|[email protected]?  
 `@@[email protected]@@@@@@@@'[email protected]@`^@@@!=jD                                                                                                        [email protected]@@@@@@@'  [email protected]@@@@#`[email protected]~ 
  [email protected]|[email protected]@@@@@@@@[email protected] [email protected]@@;[email protected]                                                                                                        .;[email protected]@@@@?`+   [email protected]@@@@@@;'Q<`
'[email protected]}[email protected]@@@@@@[email protected]{`A,`@@@@;a7q'                                                                                                       SL`=5P}, of    P{[email protected]@@@@7 @+ 
 '[email protected]@|[email protected]@@@Q|@@_   ,@[email protected]|@;~                                                                                                       [email protected]+'``[email protected]| ~y `[email protected]@@@@U @Q 
  [email protected]@[email protected]@;[email protected]    [email protected]',Q\,@>`                                                                                                        [email protected]@@@@@@Q` [email protected]: '[email protected]@@@@Q @@+
  *@[email protected]@@k*[email protected]    :g?+'< Q7                                                                                                        .`[email protected]@@@@%, [email protected]@^,y,[email protected]@@@@;@@~
  [email protected]:[email protected]@@@@U+z`  <=`[email protected]!  zi                                                                                                        c; ;fP};_7  Qh [email protected]@,[email protected]@@@[email protected]| 
  %@^'@@@@@@@Qf` @@7 [email protected]@i .^                                                                                                        [email protected]!    ^@,  |`[email protected]@@<[email protected]@@u  
  %@5 [email protected]@@@@@@8Q`[email protected]@`[email protected]@@* `                                                                                                        ;@@[email protected]     [email protected]%[email protected]@@#|[email protected]~  
  [email protected] [email protected]@@@@@@DQX`[email protected] ^@@@@;                                                                                                        ``[email protected]@@@@y      [email protected]@@@@@=`@n  
   [email protected]| [email protected]@@@@@N%@,`= `@@@@@:                                                                                                       {f ;Jjz,~` ;X  [email protected]@@@@@@f,@S  
  `[email protected]! [email protected]@@@@[email protected]    [email protected]@@@@:                                                                                                     `[email protected]' `;Uf [email protected]@~ [email protected]@@@@@[email protected]  
   `[email protected]@[email protected]@@[email protected]    ,@@i;[email protected]:                                                                                                    '@@@@@@@5 ^@#^`[email protected]@@@@@[email protected]@+  
     [email protected]@@#DK*~RD     [email protected] '~d~                                                                                                  h [email protected]@@@g^  Kj `[email protected]`[email protected]@@@@@@!   
     ,QQ:[email protected]@@@@S;>   `' ?j NX;;                                                                                                 ^@, :\i;,  `? `[email protected]@Q.`[email protected]@@@Q~    
      ,@D'@@@@@@@%Kn` QS:. [email protected]@Q>                                                                                                [email protected]!;}a      [email protected]@Q;@@@Q`     
       ,Qx*@@@@@@@@[email protected]^[email protected]@D,`[email protected]@@B;                                                                                             '@@@@@@i .T;  [email protected]@@@@X^@@i      
        [email protected]@@@@@@[email protected]@i;[email protected] ,@@@@@k`                                                                                        ~D `@@@@j. [email protected]@+  [email protected]@@@@g [email protected]~      
         `[email protected]@@@@[email protected]@* ,s  [email protected]@@@Q|                                                                                      ;@Q  |7~`` [email protected]@@[email protected]@@@@@@{'ES`      
          ^WUtJoPURQ'[email protected]@^     '[email protected]*oWf                                                                                    ,@@@K*^Tf^  Q&|;AE'@@@@@@@B'W+        
           `[email protected]@@@QDy?rc;      `5Q !i?;                                                                                `T [email protected]@@@@Q*   ;;`[email protected]@j [email protected]@@@@@!gQ         
            `S;[email protected]@@@@@@#Ay;  *Nz,;.;@@@@dL'                                                                          `{@f [email protected]@@U!      ,[email protected]@[email protected]@@@@[email protected]         
             ;g`|@@@@@@@@qN%_ [email protected]@Q' [email protected]@@@@@b;                                                                       ,[email protected]@D. ',;*' ~   '[email protected]@@@^@@@@[email protected]@R`         
              mQ,'[email protected]@@@@@@[email protected]'^[email protected]  [email protected]@@@[email protected],                                                                 's:'@@@@@@[email protected]\  `[email protected]@@@@[email protected]@@@q;           
              `[email protected]^ ;[email protected]@@@@@[email protected]+ `*;  ,[email protected]@; `;^.                                                              `[email protected] [email protected]@@@Qw=` [email protected]@Q ,^[email protected]@@@@@;;@@y,             
               `[email protected]'`~zkd%RD!+zi'``   ``^#|'@@@@@#EL:                                                     .  ^[email protected]@8.,rvz=    [email protected]*^[email protected]*[email protected]@@@@@@f !R'               
                 :7%@[email protected]@@@@@@@@QWdKy{;i#XE,[email protected]@@@@@@@@q*`                                             `^ZN; ^@@@@@@@@d^`    : ;[email protected]@?`[email protected]@@@@@z`Sq`                
                    '{'`[email protected]@@@@@@@@@@[email protected],[email protected]@@@N^:,;+'`                                         [email protected]@@~  [email protected]@@@Qh*. ';`   ;[email protected]^@@@@@Q;+QN`                 
                     `A\` `}@@@@@@@@@@%[email protected]@k~^: 'v#@Q',[email protected]@@@@@@Qdy*_                         `[email protected]@@@Q*^;zjs+  [email protected]@D,  `[email protected]@@[email protected]@@@z;[email protected]                  
                      `BQ=  '[email protected]@@@@@@@DJgQD'     ~Yqr|[email protected]@@@@@w\>;,.~!=||*^;:.      `,!**~*[email protected]@@B' @@@@@@@@@@@87.`[email protected]@@y `''y%@@@@@@@[email protected]@B>[email protected]@Q~                   
                       '[email protected]<^v5UKKbKKquiJdN%Kyz;!mZY~ ;[email protected]@@; [email protected]@@@@@@@w?~.'*[email protected]@@E;>[email protected]@@@@K;'^EgQQgK5i;`  ,wm7*[email protected],<@@@@@@@@[email protected]@8o!                     
                         [email protected]|\[email protected]@@@@@@@@@@@@#[email protected]@E{SR|   '[email protected]@@@@@D` `{&@@@@@@L  [email protected]@@@@@@@@@gj<,'jXK%j`   [email protected]@@W:[email protected]@@@@@@K,,@Qy;`                        
                            `;iv,  _\[email protected]@@@@@@@@@@[email protected]@@%^     '\yuS! `!{[email protected]@Bi~{[email protected]@@@@@@@NUKKEI=!;,`  `[email protected]@@Wr  [email protected]@[email protected]@@@@D~`LNc                            
                                \K>`  ,[email protected]@@@@@@QU,,~?nSPaUDXfYyjSL      `,^xJ!``'~;;!^^;;|uzL*+;  'i7\L?^,``[email protected]@@@@@@@*[email protected]@@[email protected]                             
                                 ,WQZ;   ;\o5Ti\[email protected]@@@@@@N%%[email protected]'      [email protected]@@@A?`    <[email protected]@@Qj^` ';i}[email protected][email protected]@@@@@@@@[email protected]@K+7%@@y`                              
                                   ^[email protected]+;|o%@@@@@@@@@@@@@@@@Q+`,+\nSqDQQ%XYcI\*!~' `'''_^*?'`+}[email protected]@QQQQQK,[email protected]@@@@@@@@@u`[email protected]&KaL'                                
                                      `,;|[email protected]@@@@@@@@@[email protected]@@@@@@WDq6byi|[email protected]@@Qy+cXKD%[email protected]@@@@@@@8\,+fn~`                                      
                                           .aQUi;,!|zJcr*[email protected]@@@@@@@@@@@@@@Q*`^[email protected]@@QWwv. '[email protected]@@@@@@@@@@[email protected]@@@@@bucyBQ<                                          
                                             ,[email protected]@@[email protected]@@@@@@@@@@@@@@Di*[email protected]@@@@@@@@@@@L;[email protected]@@@@@@@@@@@[email protected]@@@@[email protected]@WL`                                           
                                               .^<<+!!\[email protected]@Qy|[email protected]@@@@@@@@@@@[email protected]@@@@@@@@@&[email protected]}T*!_.                                              
                                                         ;[email protected]<^[email protected]@Q%K6U66qqqUm*[email protected]@@@@@N6a}JYEwt<=z'                                                       
                                                            `!czv|z7<<[email protected]>'                                                             
                                                                         .^z5aY?~`~T;`                                                                          

*/

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './Whitelist.sol';
import './ApproveUtils.sol';

// hardhat network logging
// import 'hardhat/console.sol';

///
/// @title Used only by [swappin.gifts](https://swappin.gifts]) to accept payments in any token or native coin.
/// @author swappin.gifts
/// @notice We've designed this contract to be non-upgradable. Once the contract has been deployed to the blockchain, it will never change.
/// @notice This guarantee, as provided by the blockchain, together with the complete source code of the contract, will allow any party to verify the security properties and guarantees.
/// @notice By putting security and transparency first, we hope to pave the way for a more trustless and trustable ecosystem.
/// @notice Clara pacta, boni amici.
/// @dev See README.md for more information.
///
contract Gateway is ReentrancyGuard, Whitelist {
        using Address for address;
        using SafeERC20 for IERC20;
        using ApproveUtils for IERC20;

        /// @notice emitted on succesfull payment
        event Payment(bytes32 indexed orderId, uint64 indexed refId, address indexed dest, address tokenTo, uint256 amount);

        constructor() {}
        
        ///
        /// @notice The create2 constructor alternative. Initializes the whitelist and sets the owner.
        /// @dev Setting the owner this way is secure because the DeterministicDeployFactory.deploy() is onlyOwner.
        /// @dev `_dests` and `_tokens` are pairs so arrays must have same length. Same applies to `_providers` and `_providerSpenders`.
        ///
        /// @param _dests array of allowed destination wallets
        /// @param _tokens array of allowed destination tokens
        /// @param _providers array of allowed swap providers
        /// @param _providerSpenders array of allowed swap provider spender contracts (sometimes not the same as the provider main contract)
        /// @param _ownerAddress the constructor will transfer ownership to this account
        ///
        function init(address[] memory _dests, address[] memory _tokens, address[] memory _providers, address[] memory _providerSpenders, address _ownerAddress) external onlyOwner {
                // make sure pair lists lengths match
                require(_providers.length == _providerSpenders.length, 'providers and providerSpenders length differs');
                require(_dests.length == _tokens.length, 'destinations and tokens length differs');
                // fill white list of providers
                setProviders(_providers, _providerSpenders, TRUE);
                // fill white list of destinations
                setDestinations(_dests, _tokens, TRUE);
                transferOwnership(_ownerAddress);
        }

        ///
        /// @notice Transfers `amount` of `token` from msg.sender to `dest`
        /// @notice Emits a `Payment` event
        ///
        /// @param orderId swappin.gifts order id
        /// @param refId swappin.gifts partner id
        /// @param amount amount in USD to transfer
        /// @param dest destination wallet (must be whitelisted)
        /// @param token destination token (i.e. USDC - must be whitelisted)
        ///
        function payWithUsdToken(bytes32 orderId, uint64 refId, uint256 amount, address dest, IERC20 token) external {
                // validate input
                require(amount > 1, 'invalid amount');
                require(token.balanceOf(msg.sender) >= amount, 'insufficient sender balance');
                // destination address and token are white listed
                require(validDestination(dest, address(token)) == TRUE, 'unknown destination');

                // save start balance of dest address
                uint256 startBalance = token.balanceOf(dest);

                // emit Event before external call
                emit Payment(orderId, refId, dest, address(token), amount);

                // transfer amount of tokens to dest address
                token.safeTransferFrom(msg.sender, dest, amount);

                // solidity checks and reverts on overflow (since 0.8 or so)
                // verify transferred amount
                require(token.balanceOf(dest) - startBalance == amount, 'transferred amount invalid');
        }

        ///
        /// @notice Accepts `amountFrom` ETH. Sends ETH to swap provider, which sends `token` back.
        /// @notice Sends received `token` to `dest`
        /// @notice Emits an event
        //
        /// @param orderId swappin.gifts order id
        /// @param refId swappin.gifts partner id
        /// @param amountFrom amount of ETH to pay
        /// @param minAmountTo minimum amount of USD that is allowed (otherwise tx will revert)
        /// @param swapProvider a dex aggregator or dex address (must be whitelisted)
        /// @param swapCalldata calldata to pass arguments to the swap provider
        /// @param dest destination wallet (must be whitelisted)
        /// @param token destination token (i.e. USDC - must be whitelisted)
        ///
        function payWithEth(
                bytes32 orderId,
                uint64 refId,
                uint256 amountFrom,
                uint256 minAmountTo,
                address swapProvider,
                bytes calldata swapCalldata,
                address dest,
                IERC20 token
        ) external payable nonReentrant {
                // validate input
                require(msg.value == amountFrom, 'msg.value != amountFrom');
                require(minAmountTo > 1, 'invalid minAmountTo');
                require(amountFrom > 0, 'invalid amountFrom');
                // destination address and token are white listed
                require(validDestination(dest, address(token)) == TRUE, 'unknown destination');
                // provider address is white listed
                require(validProvider(swapProvider) == TRUE, 'unknown provider');

                // call provider to convert ETH to tokens
                uint256 amountReceived = swapEth(swapProvider, swapCalldata, token, minAmountTo);

                // send tokens to dest address
                transferToDest(dest, token, amountReceived, minAmountTo);

                // emit Event
                emit Payment(orderId, refId, dest, address(token), amountReceived);
        }

        ///
        /// @notice Accepts `amountFrom` of `tokenFrom`. Converts `tokenFrom` to `tokenTo` via a swap provider
        /// @notice Sends `tokenTo` to `dest`
        /// @notice Emits an event
        ///
        /// @param orderId swappin.gifts order id
        /// @param refId swappin.gifts partner id
        /// @param swapProvider  a dex aggregator or dex address (must be whitelisted)
        /// @param providerSpender  a dex aggregator or dex spender address (must be whitelisted)
        /// @param swapCalldata calldata to pass arguments to the swap provider
        /// @param tokenFrom the token the user pays with
        /// @param tokenTo destination token (i.e. USDC - must be whitelisted)
        /// @param amountFrom  amount of token to pay
        /// @param minAmountTo  minimum amount of USD that is allowed (otherwise tx will revert)
        /// @param dest destination wallet (must be whitelisted)
        ///
        function payWithAnyToken(
                bytes32 orderId,
                uint64 refId,
                address swapProvider,
                address providerSpender,
                bytes calldata swapCalldata,
                IERC20 tokenFrom,
                IERC20 tokenTo,
                uint256 amountFrom,
                uint256 minAmountTo,
                address dest
        ) external nonReentrant {
                // validate input
                require(amountFrom > 0, 'invalid amountFrom');
                require(minAmountTo > 1, 'invalid minAmountTo');
                require(tokenFrom.balanceOf(msg.sender) >= amountFrom, 'insufficient sender balance');
                // destination address and token are white listed
                require(validDestination(dest, address(tokenTo)) == TRUE, 'unknown destination');
                // provider address and provider spender address are white listed
                require(validProviderSpender(swapProvider, providerSpender) == TRUE, 'unknown provider');

                // save current token balance
                uint256 tokenFromBalance = tokenFrom.balanceOf(address(this));
                // transfer tokenFrom from sender to this contract
                tokenFrom.safeTransferFrom(msg.sender, address(this), amountFrom);
                // verify received tokenFrom amount
                require(tokenFrom.balanceOf(address(this)) - tokenFromBalance == amountFrom, 'invalid amount of tokenFrom received');

                // call provider to convert tokenFrom to tokenTo
                uint256 amountReceived = swapToken(swapProvider, providerSpender, swapCalldata, tokenFrom, tokenTo, amountFrom, minAmountTo);

                // verify transfered all received tokenFrom to provider
                require(tokenFromBalance == tokenFrom.balanceOf(address(this)), 'invalid amount transfered to swap provider');

                // send tokens to dest address
                transferToDest(dest, tokenTo, amountReceived, minAmountTo);

                // emit Event
                emit Payment(orderId, refId, dest, address(tokenTo), amountReceived);
        }

        ///
        /// @notice Call DEX provider to convert ETH to `token`
        ///
        function swapEth(address swapProvider, bytes calldata swapCalldata, IERC20 token, uint256 minAmountTo) private returns (uint256) {
                // save this contract's ETH  balance
                uint256 ethStartBalance = address(this).balance;
                // save this contract's token balance
                uint256 startBalance = token.balanceOf(address(this));

                // call provider to convert ETH to token
                swapProvider.functionCallWithValue(swapCalldata, msg.value);

                // verify received tokens amount from provider
                uint256 receivedAmount = token.balanceOf(address(this)) - startBalance;
                require(receivedAmount >= minAmountTo, 'invalid amount of token from swap provider');

                // verify transfered all received ETH to provider
                require(ethStartBalance - address(this).balance == msg.value, 'invalid amount transferred to swap provider');

                // return the actual amount calculated from balances (not what the provider might have returned)
                return receivedAmount;
        }

        ///
        /// @notice Call DEX provider to convert `tokenFrom` to `tokenTo`
        ///
        function swapToken(
                address swapProvider,
                address providerSpender,
                bytes calldata swapCalldata,
                IERC20 tokenFrom,
                IERC20 tokenTo,
                uint256 amountFrom,
                uint256 minAmountTo
        ) private returns (uint256) {
                // allow providerSpender to spend amountFrom of tokenFrom tokens held by this contract
                tokenFrom.safeApproveImproved(providerSpender, amountFrom);

                // save start tokenTo balance
                uint256 startBalance = tokenTo.balanceOf(address(this));

                // call swap provider
                swapProvider.functionCall(swapCalldata);

                // verify tokenTo amount received from provider corresponds to what was quoted
                uint256 receivedAmount = tokenTo.balanceOf(address(this)) - startBalance;
                require(receivedAmount >= minAmountTo, 'received invalid destToken amount from swap provider');

                // reset providerSpender allowance to 0
                tokenFrom.zeroAllowance(providerSpender);

                // return the actual amount calculated from balances
                return receivedAmount;
        }

        ///
        /// @notice Sends `toToken` received from swap provider to `dest` address
        ///
        function transferToDest(address dest, IERC20 tokenTo, uint256 receivedAmount, uint256 minAmountTo) private {
                // save dest address start balance
                uint256 startBalance = tokenTo.balanceOf(dest);

                // send tokenTo to dest address
                tokenTo.safeTransfer(dest, receivedAmount);

                // verify transfered full received amount and amount is valid
                uint256 destAmount = tokenTo.balanceOf(dest) - startBalance;
                require(destAmount == receivedAmount && destAmount >= minAmountTo, 'invalid amount transfered to dest');
        }
}