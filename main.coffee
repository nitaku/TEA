doclist = new Items()
doclist.add new Item
  id: 1
  name: 'pippo'
doclist.add new Item
  id: 2
  name: 'topolino'

sel = new ItemSelection()

navigator = new Navigator
  el: '#navigator'
  selection: sel
  items: doclist

sel.on 'change', () ->
  # destroy the old editor
  d3.select('#editor').selectAll '*'
    .remove()

  # destroy the old graph view
  d3.select('#graph_view').selectAll '*'
    .remove()

  doc = new Document
    code: '''
      Molto Reverendo Padre, mio Signor Colendissimo
      La lettera di <Vostra Reverenza> mi è stata tanto più grata quanto più
      desiderata et meno aspettata, et havendomi ella trovato assai indisposto, et
      quasi fermo in letto mi ha in gran parte sollevato dal male, portandomi il
      guadagno di un tanto testimonio alla verità delle mie nuove osservazioni, il
      quale prodotto ha guadagnato alcuno degl’increduli, ma però i più ostinati
      persistono, et reputano la lettera di Vostra Reverenza o finita o scrittami a
      compiacenza et insomma aspettano che io trovi modo di far venire almeno
      uno dei quattro Pianeti Medicei di cielo in terra a dar conto dell’esser loro,
      et chiarir questi dubbii; altramente non bisogna che io speri il loro assenso.
      Io credevo a quest’ora dovere essere a Roma, havendo non piccolo
      bisogno di venirvi, ma il male mi ha trattenuto, tuttavia spero in breve di
      venirvi, dove con strumento eccellente vedremo il tutto; in tanto non
      voglio celare a Vostra Reverenza quello che ho osservato in Venere da 3.
      mesi in qua.
      Sappia dunque come nel principio della sua apparizione vespertina la
      cominciai ad osservare, et la veddi di figura rotonda, ma piccolissima:
      continuando poi le osservazioni, venne crescendo in mole notabilmente, et
      pur mantenendosi circolare, sin che avvicinandosi alla maxima digressione
      cominciò à diminuir dalla rotondità nella parte aversa al sole, et in pochi
      giorni si ridusse alla figura semicircolare; nella qual figura si è mantenuta
      un pezzo, cioè è sino che ha cominciato a ritirarsi verso il sole,
      allontanandosi pian piano dalla tangente; hora comincia a farsi
      notabilmente cornicolata

      et così anderà assottigliandosi sin che si vedrà vespertina; et a suo tempo la
      vedremo mattutina, con le sue cornicelle sottilissime, et averse al Sole, le
      quali intorno alla massima digressione faranno mezzo cerchio, il quale
      manterranno inalterato per molti giorni; passerà poi Venere dal
      mezzocerchio al tutto tondo prestissimo; et poi per molti mesi la vedremo
      così interamente circolare, ma piccolina, sì che il suo diametro non sarà la
      6.a parte di quello che apparisce adesso; io ho modo di vederla così netta,
      così schietta, et così terminata, come veggiamo l’istessa luna con l’occhio
      naturale; et la veggo adesso di diametro eguale al semidiametro della Luna
      veduta con la vista semplice. Hora eccoci S. mio chiariti come Venere (et
      indubitatamente farà l’istesso Mercurio) và intorno al Sole, centro
      senz’alcun dubbio delle massime rivoluzioni di tutti i Pianeti: in oltre
      siamo certi come essi pianeti sono per se tenebrosi, et solo risplendono
      illustrati dal Sole: il che non credo che occorra delle Stelle fisse per alcune
      mie osservazioni; et come questo sistema de i pianeti sta sicuramente in
      altra maniera di quello che si è comunemente tenuto; così nel determinare
      le grandezze delle Stelle (trattone il Sole et la Luna) si sono presi errori
      nella maggior parte de i Pianeti et in tutte le fisse di 3. 4. et 5. mila per
      cento, et più ancora.
      Quanto a Saturno, non mi meraviglio che non l’habbino potuto
      distintamente osservare, prima perché ci bisogna strumento che moltiplichi
      le superficie vedute almanco 1000 volte; di più Saturno adesso è tanto
      lontano dalla terra, che non si vede

      se non piccolissimo, tuttavia l’ho fatto vedere qui a molti dei loro fratelli
      così distintamente che non vi hanno alcuna dubitanza et si vede giusto così
      o0o. Cinque mesi sono si vedeva assai maggiore, da quel tempo in qua è
      diminuito molto, né però si è mutata pure un capello la costituzione delle
      sue 3. stelle, le quali per quanto io stimo sono esattamente parallele non al
      zodiaco, ma all’Equinoziale.
      La notte passata osservai l’Eclissi della Luna, ma però senza novità alcuna,
      non havendo veduto altro che quello appunto che io ero immaginato cioè
      che il taglio dell’ombra è indeterminantissimo, et confuso, come quello
      che è cagionato dal corpo della Terra posto lontanissimo dalla Luna dove
      che le ombre si scorgono nella medesima Luna cagionate dalle eminenze
      che sono nell’istesso corpo, sono terminate crude, et taglienti delle quali
      eminenze, rupi et grandissimi tratti gioghi eminentissimi sparsi per tutta la
      parte più lucida della Luna, Vostra Reverenza non ne habbia dubbio
      alcuno, perché a chi haverà buona vista, et intenderà un poco poco di
      perspettiva, et di ragione di ombre, et di chiari, lo farò così manifestamente
      toccar con mano, quanto manifestamente siamo, certi delle montagne, et
      delle valli terrestri, et niente meno: hora la notte passata con l’occasione
      dell’aspettar l’eclissi osservai molte volte i Pianeti Medicei, notando le
      loro mutazioni della medesima notte in diverse hore, le quali furono tali,
      notando anco le distanze tra essi et Giove in proporzione al diametro
      apparente di esso Giove:

      Die 29 Decembris Hora seguenti noctis 3.a

      Vedremo dunque quanto ci piacerà le mutazioni anco nella medesima
      notte; ma perché le osservazioni che ho fatte da 2. mesi in qua, le ho fatte
      tutte la sera, non ho potuto incontrare quelle che ella mi ha mandate, fatte
      costà la mattina; perche come vede in 7. o vero 8. hore fanno gran
      mutazione.
      Hora per rispondere interamente alla sua lettera restami di dirgli come ho
      fatto alcuni vetri assai grandi, benché poi ne ricuopra gran parte, et questo
      per 2. ragioni, l’una per potergli lavorar più giusti, essendo che una
      superficie spaziosa si mantiene meglio nella debita figura, che una piccola;
      l’altra è che volendo veder più grande spazio in un’occhiata si può scoprire
      il vetro, ma bisogna presso all’occhio mettere un vetro meno acuto, et
      scorciare il cannone, altramente si vedrebbono gl’oggetti assai annebbiati.
      Che poi tale strumento sia incomodo ad usarsi, un poco di pratica leva ogni
      incomodità et io gli mostrerò come lo uso facilissimamente, et con minor
      fatica assai che altri non fà nell’astrolabio, quadrante armille, o altro
      astronomico strumento. Haverò soverchiamente tediata Sua Reverenza
      scusi il diletto che ho nel trattar seco, et continui di conservarmi la sua
      grazia, di che la supplico con ogni instanza, come anco che ella mi
      procacci quella dell’altro Padre Cristoforo suo discepolo da me
      stimatissimo per le relazioni che ho del suo gran valore nelle matematiche.
      Et per fine all’uno et all’altro con ogni reverenza bacio le mani, et dal
      Signore Dio prego felicità.
      Di Firenze il 30 di Dicembre 1610.
              Di Vostra Signoria Molto Reverenda Servitore Devotissimo
                                                                Galileo Galilei
    '''

  # stub of Editor view
  doc.on 'parse_error', () ->
    console.log 'parse error'

  editor = new Editor
    el: '#editor'
    model: doc

  graph_view = new GraphView
    el: '#graph_view'
    model: doc

  # do the first parsing of the document
  doc.parse()
  
