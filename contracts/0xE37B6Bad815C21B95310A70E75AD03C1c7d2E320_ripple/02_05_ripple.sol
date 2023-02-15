// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ripple
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                      //
//                                                                                                                                                                                                      //
//                                                                                                                                                                                                      //
//                                                                                            .'`""^`..                                                                                                 //
//                                                                                   ,+_?)z0ZZQQQOOOOZmwqQt[?i.                                                                                         //
//                                                                             ^>-fQ0QQQQCUYYYYzXzzvvvczzccLZZpq(+:                                                                                     //
//                                                                          ,{LbpdppppwLCUJUUYXYzzcccczvvuuvnnvrLZZ0{l.                                                                                 //
//                                                                        :jhddbbppppqwwmqUUUYUXcczcucuuuvxuuxnxvjnuZmQ|:                                                                               //
//                                                                      '{hbbkbdddpqqpqwwwmmmJXYzccvvvununuxxvxrxvxrxxcmZu<`                                                                            //
//                                                                     ^Lkdbddddqpdpqqwqwqmqmm0UXcvvuvunnnnunrvxxrurxnfjxYmQ]'                                                                          //
//                                                                      .`^^'lvmwpqqqwwqqwmwwmm0cuvvuuunnuxxrufvxxjxfjnjfnxUZm-.                                                                        //
//                                                                          IvQ}'IcmwqqwwqwwmmwZ0Ucuvunnxxnrufvfnrxrnjfunjttxz0mi                                                                       //
//                                                                             ^|Q_.cwqqwwqwwmmwmLcznuuuvrnnnufvtnfnjxxjjjnj(tnxOm,                                                                     //
//                                                                               .(Yi`CwwqwmwmZZZw0cnnvuuxnnnxxjvjnrxrfrxjfjxftxcnQL                                                                    //
//                                                                                 if/"f0wwZmmmZmmJnvunvxnxurxnujxrrxrrfrrrrtjrjxtrXQ|                                                                  //
//                                                                                  ,/x^XmmmmmmmmmUjunnnuxvjunxxrrnjxrjxxfxjrfjr/u/(/mn^                                                                //
//                                           ^](}}1/tjjf1;                           ~j/'ZmZZZmOZZYfxuzuvxuxxurxxurufurrxrjftn|jffvf|ft0r                                                               //
//                                       >[(t/|/////){l^                              |xl^qmmOOZZZLnxcuuruxnnnruuxnfrrjfrrffjxftxx|tv1rxvn;                             .^I!I.                          //
//                                 >}`"~)///////t}){:                                 }rv.UOZZOZZZCunucuvnxncnrxrxjxjjrnrrrjntu/x/ft/c{r)jX]                     .![}/nn/)||i'                          //
//             I+"               :[!`<)tttttttf1{1:                                   ^|x'[ZZOOOOQcxvzzunxcnxvnc/vvfrjrj/rxxfrju|jfr/)xf({)j/,               `_[|fjrt)1}{}i.                            //
//            .<|!              :1I;(rjjjfffjt1(I                                     .(f`.QZ0OOOCxnvcnuuuxnjnrxcxrnxnrfxjfffjrrr(nfxttntj))fx~           i]fffjjjf){{{}[:                              //
//                             "{;"{nnxxxrr/))_                                       ^)f` QOO00QYcvvvuxvnnjnnvnxjun//trtffxrffntu)utjtx|fx|)(f_      '-[jjrxrjf|){{11{}:                               //
//                            .~j <zvvuunxf||1[>+^              .`:l>~+<'             -/f'^QO0OOQnxuvvuvnnnnvcntjuufnnrjnjnnunxfntu(X(jfff(r()(j1,,<-jjrxxxnxr/)1{{{{{{l.                               //
//                :^          "(:,/XXzcvur//)((/||(rnnrrrxxnnrjtttffjrf/~             1/n.|00O0Lcvcvnnvvvxnvcnjvuurrvcxnfxnxrjucvu|x)n(rffr|t)/)/nnnnnuuuuunf()111{111],                                //
//          `>i`  [>          :v +mJUYXzuff|(|/||/xjjrjrjfjjjjjjr(rt]()+             :)/{.J00OOLccuvvvcnnuuvnxxvvnnvujxxvnjtrnrxnjftu/r/rj/f|t()11fcccvcccvf(((11))111i.                                //
//          lnj>              !0 ~mQCJUYnf()(|)(/rxxxxxxxrxrrjx{(]_i'                {/t,^Z00OQvvczcvvnnvnxxcnnncrnxcxfrjxfuvcxxxz|u(u(r/tt(f/))t()jcYYXYv|(1|((1))))(l                                 //
//           ..               !0 +dZ0QLUuvj(||1(tuuuuunnnnnx)}_^                    _(|}'r000QcvucuvcvvnnvvvncznrvuXvvuxnjnvcunfvfnfY1ctxf/ftt(t({((tcUz/)/f|((())(((/!                                 //
//                     .      :v -oqwZOYnf|||((|ucccccvvvuj)!.                     l{(/^:U00OUvzccvvvnnvcunuzcnjUnurnvvrnvcvtjvvru)X1v(vttt/f|(//)1(11ujttt/t(|/((((|/!                                 //
//                ^,'  +'     ,v<lJkdpqJvf||(|)/UYYYXXXXXn_`                      l{|(l.X000cvccczzzcccuvvzznvYuuznzcXncXvxxrrrxxfurjfujnjrjtftt/(t()1{/jjftt//t(//|/ti                                 //
//               .}zi  (^     "cU'1oahkQXr||||/tUCJJJUUUv~                       >)|(]`}L0OccuzXzzvXzzvzYvncUzcvYzXnXznnnXuxXUztuftz)c|cnrrrrf/)//t||)))fjrrrtjj/jt/tf>                                 //
//            .   ^l^  1>      !X;-hM##pLr/t|(//n0QQQLCX1I                     '+||(]^lU0OccJXXYXcvcYXzcvYUUUUUzzzvXcnvXuuYUXxvUvzvnruztfjrnfrrrfff(|/)((trnxrxrtxjjffi                                 //
//          !zf:       `x'     ;Q0 1*MM#mrff/|/ttZmZZOOX[-:                  '<|||(1,;XOmJYXYYUXzUYUzXzcXXuzUUvXYxuznYcnzUuuQLv/nvnYQurYvfjtUn||jft|(/))()1rnnunrnjjjr+.                                //
//          :/f;        Y>      <bj-d&WWppXrj||ftxwqwmwY[{[l.              "[)||/)<'>XO0CJJYvcXYXXXXCCUzXzUcnzXvvXzUYuczvr_^.                .'>f/trt)t)1)(/nnuunuxnnxtI                                //
//                      <z.     .?U>(W888dvnxt//rtXppwwU){1{]>`         .l)/tt/t|i.+UwJUUJXXCXXuzXYJYJUUUccUYLCYUQQzr^`.        `_cCLUYJYJC|,'     .^1})(1()truuvuxnurr<.                               //
//                  f(^  vc^     "fYix%888mvxnxtxrrcqpwmX11{{{{[]l.  .~)ttftjjf|i (00LJUCCYzJCLJJCJUJXcXUYLJQvQcC;"       IfxfUQxurJXczzXzcvxuzx|c[`   `,)}))(tuvvvuuxru!                               //
//            -n!   '`.  ,U+      "fZ]{bW&#UvzcuuvnnuXUO0v11{11{1[(|frrrjxrnnj-``tZLUJLJYCYCUYJQLLJCXJJUYLLOzt;'      >uvQXcCUxcJUUUvvzUrzuznzxnvzfrx|r"  ."~{1/rzzzcnxn/,                              //
//            <(:   `r|^  [Zf      ^xa)iZMWW0UJYXXzczzcvnunjjrfjxxxuxuvczYJnI' ?LQCLCJJCCCQLLCLJUYCJLQC0OL(i'      !zzJYJXJJUczcXXnYYUzczvucXuuczxcntzXfv/i  ."i|tuvcuunut"                             //
//                   tC;   fdU"      iUp|L#MMm0LLJCUUQLLCCJYYXYXzYYJJUJCU[I  iX0LQCJJCL0Q0CQQL0CQ0Q0OO0r_^      "YYCLUJLJUCUcUYXUuuc0cvvUnuczYzuvxnzuunYju|X[[   ^-xuvvvuu(`                            //
//             .-_.  "xn^   (OY`      ^_OwcjaWaQZ00QL0Zm00LC0Q000OZZOQ+i   ,fQQLLCL00QQ0O0QQQ0QCQ00ZX1:      .jzCJUCzUYXJUUcXXcvzYzXxcYYcXvuvunvzcvvzzcnzuxtvvn}-  'I1nnuvuf;                           //
//              (q]   {0L^  'nOC]        +zaC*L&kwqmmwwqwpqwqqdppZ{_.    "fLQLL0QLZZOZZOQ0Q0OmL0mQu!       <|0CUQUJXUYzYYzvzLUzJYYYccUvnccXYvzUXuvcvuuUjvUunnccXXj[i  ,i|rnun)'                         //
//               !;    xmw|  `tQOC_         _{ja*8&***ahkkahU|}i'      "rZLLQO0Q0mZL0mZ0wwwOmwOJ+"      '}COO0JJQJUJCJJJXYUUJzYCXcYUzUXcYuJcYJXcnccczzvzjuCucunuxcYYt-,  l<ffrn[!                       //
//               )Z}'   fQZ0} ^t000X~.            'I<~<l^           .|vZ0LZOO0ZmZO0mqOZwwdZdQr_       >tCLJQJUCYJLQCJLJJUUCUUUQCLYYL0LxJQJXcJUXUUYYvJfcvUfJzrccYvjxzYzv1<`  "~/tfr_"                    //
//         .;l   .xdj,   nmZ0p1'+0mZ0z/i.                        ;{nZCOQmOOZwm0OqqmpqdwZpmm1'      `+XZ00CLQCLQ0QCYJJCYQ00LJJ0YLUJJ0zLzC0XcYYUnCYvzzYXnCvOrXYrxvJXxrzJJYcY}:    +i1t/_>`                //
//                :XkL_'  vpbOZQ{/Jwwm0Q0f{I'              .^_1rm0mLZqOwmwpZOmpdwwbqwkdk|;       :/J00QLQQC0J00ZJJULJJ0JCczJZCOJOUmUvJY0J0L0CQYJUzXcJzzJzcJrJuvnnvXzuzJJJJUzc>'     `<~i?_l:'           //
//           .`    _OhoY?. (khoqpdZCwZmpZZmQOdv[}[[[[[}}}f0pwOO0wZmdpwpqwdwdwwdbppqbbXf^      .Ifw00LC0O0QZQ0JZJ0YLOQZLOL0ZmZwCUqLX0YwXJOCOCQCXJXXYvLcCCvYUvJvYznnvXcvnnXJLQJzux~.           .`.        //
//            ?x:   _Zka*W{^'Jo#odbbkdpqqqppqw0ZqqwOQ000mOZwZZqmqwdpdqbqpdbdbhbdpb0cl       '}LZmOOOOZOQmwOOZZLZOm00L0OQmZOwC0YCLbwmOOOCJQ0JU0XUvzUvcvYUXLuLnvJcccnrvXvxuXXYJCLCY/];                    //
//             _X['  ~ZMoWMkZ_l0ba#hbbppwwbmpkqObmpqwqmwqmwwwqdbmbbbqdppqaphohppC+        I1h0mZ0mmOOmmmQwOOLqpO0dOCQw0qdOUQbqQUk0XXhmmZUOmLQCJCQmOCUuCJzwnCYvQzurjt|trxjffxcUzujfjxf;.                 //
//              'tY<. .C#M8o8&#oqob*hhkkkbkbdhZ0wmbqqhqppqbdbbddqhp*pk*k*b#kdC)        .<hmdZZmwwmOOmZwqdOdqdLZwp0qhh00Z0mmOmd0pmObpOb0QmQZO0Q00QO00LLQ00pdkdpmQJYcvvzXvrf(tut[jUcxYYz/_"               //
//                ?OO-' Qo#8&#%&WW#*akahbdapphbbaZ*kbapokbobokohkobdMd#hakJ/         ;rpbqwwpZZZpwZOqbpZZbwdQ#m00kkqkCwLQmqbpkpZ#0LwLYXzunnxrjt|//tfjrrxnvccYXvuULJJYXcuuvvczcXL[_nftnvnx[".            //
//                  nb8[``k8&&8WW&M8W*oWoa##*bhooO#ba*b#ooakoa#oa#oao&ZQ^         '!mkqdqmbmmpddmwa#qqkkoQpbkChO#pqwdpomwhddmdkmUzvnt(|_.               '-/1|runccuczvvccvuunnxxuvunt,;1ftjj~'          //
//                    tqa#I"#WWM&W%&#W%&W#aobMMWMoMk*#dMoMooMbMak&bb_          ."U*kbqpbqhQhbZwwpMpq*bCwqopdO#kwxWUbQwOqb#bQJvr/1~.       '^"":;III;,""^.      ,1)/xncXrjvxrnnrxxnxnuuu(". ij|rl.       //
//                       hdb8_ZMM&8W8B&M#*#W8&#*##&&W8WWho#kMWoo_.           'j#ahhdkbdqdabd*Mp*aQohbaoqpqoZMZoZWZkmb8odLzvjt!      [email protected]%8%%BB%%Mdm#&1,.     >1)txuvUU?[Yxtrnnxnunu|;    ^j"     //
//                         'q#h*p+L%8W8%BBBB88%[email protected]@@@@[email protected]&oMJl.            .}Mbkhadda*ddhkbbko%pOb#mbOQoWbdqZWb8dohBoMOcnf?"     ^m%[email protected]&W#ooahhhhaahahaaodhaokOqY`     "}1)/fxnjcn";{cvjjxunxI         //
//                            '^>[email protected][email protected]@BB8&MW8a(^^`               >MaokobahhbhdWqk%L8q8d#k#kd*oMpahkZMh#ko8&#Zuj[`.   'v#B%o*o*##*ad0QOOOQJXXUCOppwppwwbwQ0OqQL/^     '.'-j/fxnxz|^'''':trxi      //
//                                  .^:;;;;;;;:,'                    (oo*aoaok#oka*bW#o#k%CaQoahb8ok#MapZa&q&%&WoYf(:'   'xMBMo*MM#ZYCJYzQZxi"","""",[UO0u)jJ0QQUJCZLC0YJ>          .`^^"![|f["   `'    //
//             .l;                                               :mpMao#*okM#*o#W%M8w*kpZ8o#o#&MkZohadkbM%W%%Wazt["   .}#%#a*M#Z0UzQ]::.   ',1LpbkkbdZr;`..;;:|Jj/nczYXUUJYz!                   ..      //
//               ;cCi                                       .iUqMM#&#%8&#8#o*oM#Mob#&ohb%a*b8WahoW*kb&*M%%%Wdnx:.   ip*#ao*hp0Uz<l. '}qCwW#qXffjnYLLc/)(fJwZzCL{^:I[v/tjnzcuvzx^                        //
//                 iphwc"                               IxZk8MMW&#WBM%8#&*W&W##oaoao&*%M*#hod#k#WM#&8%BB%&dY>^    iwWhaoapLL1!` ^JX#bjcXfcQQJXzcvnnnjfft|/jvzf))uZXcf<!<jt/fnunrjf.                     //
//                   ~h8%BZ0L(..                ."rQQ0*8&W8&W88&%M8W%aWW#&*Wo#obaMWa#W#MWhqWh8&M%WBBBB%&hfi.    Caoo*oaZzj; i(UoOuzvQLUXJu<!><i;^....'";i~<lirUv((/({)zrx>!l(f(/njj]<                   //
//                     +v&%888%BB%MdOLCCL0wkW%BB%&W%%8&W88W&W&&&M%#WM%#BW8Wa#&M&88oho##k&[email protected]%%B%%%8q|,    :vWha*apmtI'+_cUCCJLCJC~+:        ,_)fxuuxj1>.     ^>>_rx)1[+){f"">~x}ttf>^                //
//                       '/@B%%%%%%%%88888%%%%%88%&&B8&%88%W%&8B*8&#@W#%M##M8**W&*hM&a8bBMBB%B%%B%%&L>     [UkkdhhQQ/,;>{zzJLQLC}<.    inf/(1}?<"          `l_+" "<:  '!><{1ll[^1 `~<1|]];              //
//                          fmB%8%8888888%888%888B&%%%8B%%%8%%8%888&BM%*M%M8W*MM#&*W%8%%%%%%%%%%8q}^     }mhkqpZM(n_`<1vCJOZj],   .j{/1l                              '.  `  il`~">"'"`!i_>;`           //
//                            ,YM%88888888%88%%8%%%88B%B88%8B8%B&B&%B#&88%MM&8&%%%BB%%%%%%%%%8d/^     .+CdpO0btc~}'+[r0Z0v-"   +]f[.                                             .:`',  ...^`.          //
//                               >Q#%%8888%88%888888%B%B%8%8%&%%%B&%%&%8%%8B8%BB%%%%888%%%BQn.      ;)JqQQUOY(t .{j)0LX?;   ~](;                 .;>~~>i!l;,'                                           //
//                                  -Uk%%%8%%8%8888%%%%B%%%8%&&88BW8BWB8BB%B%%%%%%%%%%8WL(        :rmLCuCc}<['.lx{XXt_   ;_{!     "<.?<    `l:~(>.                                                      //
//                                     "jQ*88%%%%B%88%%%%%%%%8%88%%8%%%%%%%%%%%%%%%WwU;        `</LXrrr/-(; ;I:}ur]'  .,}?    .li-'      .'                                                             //
//                                         ./0ZMB%8%%%%%%%%%%%%B%%%%%%%%%BB%%%&bOf:          ^_Cnr/)-]~l' '_^,{/i   .,i,    ,?:                                                                         //
//                                               `tOqpk#8%BB%%%%%%%BB%8#bpqJ].             "/?/+~;lI:" ."' `I;!    "!.    ."`                                                                           //
//                                                          .......                      "`l.^.'.''      ...      ,      ..                                                                             //
//                                                                                                                                                                                                      //
//                                                                                                                                                                                                      //
//                                                                                                                                        ..                                                            //
//            |BBBBBBBBz^   ?Bk   1BBBBBBBB/`   BBBBBBBBd-   UBB~        iMBBBBBBBBB-        IBBBBBBBBBBBB~     'oBb      .XBBBBBBBBBBBa [email protected]:                                                           //
//            |$Li""""[email protected]:  ?$a   1$O>""""q$%;  $BL""""([email protected]  J$$~        iW$0""""""".        .""""t$%r"""".     '*$k       `""""k$#;"""^ ~$w:                                                           //
//            |$J:     h$o. ?$a   1$Q;     p$v' $BJ     ($%t J$$~        iW$L            `        ($%t          '*$k            b$*`     [email protected]$$%Z!   C*@[email protected]%hr   j$qq%@1'[email protected]*8$$$%L   "vWB$$$8#;      //
//            |$0+III]mB$!  ?$a   1$Z+III1w%$I  $BQIII>n#$c' J$$~        iW$B888888[   [email protected]$$J      ($%t          '*$k            b$*`     ~$$OI'.>m$]  [email protected]&i. '[%BJ  j$$nI^. h$$tl..?$Mt }M$c"  .Io$j     //
//            /[email protected]`   ?$a   1$$$$$$$q}`   $$$$$$$WcI.  J$$~        iW$ZIIIIII`   <W$k;      ($%t          'B$k            b$*`     ~$w;    U$] 1W$^     ~$d< j$r.    [email protected]   !$8c |[email protected]%[email protected][email protected]    //
//            |$J:  ,[email protected]#!   ?$a   1$Q;          $BJ          J$$~        iW$L                     ($%t          :$8x            b$*`     ~$w:    U$] 'a$w    ;d$O. j$r.    [email protected]   !$8c )8%f`'```Ut^     //
//            |$J:    }M$L. ?$a   1$QI          $BJ          J$$&WWWWWWh`iW$%WWWWWWW}.            ($%t    ^hBad#$8f             b$*`     ~$m:    U$]  ;YB$hw*$Mt^  j$r.    [email protected]   !$8c  !0$#mQd%@|.     //
//            :_I      l+_  '_<   ,_l           _+`          I+________~ 'i_________"             "+<"     .~1))<               >_;      ^_!     l_"     >)){I     ;_;     l+i    '~~"    `<{)],        //
//                                                                                                                                                                                                      //
//                                                                                                                                                                                                      //
//                                                                                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ripple is ERC721Creator {
    constructor() ERC721Creator("Ripple", "ripple") {}
}