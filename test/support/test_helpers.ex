defmodule Chunker.TestHelpers do
  @moduledoc false
  @doc """
  Extracts the text content from a single `Chunk` struct.
  """
  def chunk_text(%Chunker.Chunk{} = chunk), do: chunk.text

  @doc """
  Extracts the text content from a list of `Chunk` structs.
  """
  def extract_text_from_chunks(chunks) do
    Enum.map(chunks, &chunk_text/1)
  end

  def first_split_hamlet do
    [
      "THE TRAGEDY OF HAMLET, PRINCE OF DENMARK\n\n\nby William Shakespeare\n\n\n\nDramatis Personae\n\n  Claudius, King of Denmark.\n  Marcellus, Officer.\n  Hamlet, son to the former, and nephew to the present king.\n  Polonius, Lord Chamberlain.\n  Horatio, friend to Hamlet.\n  Laertes, son to Polonius.\n  Voltemand, courtier.\n  Cornelius, courtier.\n  Rosencrantz, courtier.\n  Guildenstern, courtier.\n  Osric, courtier.\n  A Gentleman, courtier.\n  A Priest.\n  Marcellus, officer.\n  Bernardo, officer.\n  Francisco, a soldier\n  Reynaldo, servant to Polonius.\n  Players.\n  Two Clowns, gravediggers.\n  Fortinbras, Prince of Norway.  \n  A Norwegian Captain.\n  English Ambassadors.\n\n  Getrude, Queen of Denmark, mother to Hamlet.\n  Ophelia, daughter to Polonius.\n\n  Ghost of Hamlet's Father.\n\n  Lords, ladies, Officers, Soldiers, Sailors, Messengers, Attendants.\n\n\n\n\n\nSCENE.- Elsinore.\n\n\nACT I. Scene I.\nElsinore. A platform before the Castle.",
      "\n\n  Ghost of Hamlet's Father.\n\n  Lords, ladies, Officers, Soldiers, Sailors, Messengers, Attendants.\n\n\n\n\n\nSCENE.- Elsinore.\n\n\nACT I. Scene I.\nElsinore. A platform before the Castle.\n\nEnter two Sentinels-[first,] Francisco, [who paces up and down\nat his post; then] Bernardo, [who approaches him].\n\n  Ber. Who's there.?\n  Fran. Nay, answer me. Stand and unfold yourself.\n  Ber. Long live the King!\n  Fran. Bernardo?\n  Ber. He.\n  Fran. You come most carefully upon your hour.\n  Ber. 'Tis now struck twelve. Get thee to bed, Francisco.\n  Fran. For this relief much thanks. 'Tis bitter cold,\n    And I am sick at heart.\n  Ber. Have you had quiet guard?\n  Fran. Not a mouse stirring.\n  Ber. Well, good night.\n    If you do meet Horatio and Marcellus,\n    The rivals of my watch, bid them make haste.\n\n                    Enter Horatio and Marcellus.  "
    ]
  end
end
