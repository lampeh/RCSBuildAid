/* Copyright © 2013-2020, Elián Hanisch <lambdae2@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

using UnityEngine;

namespace RCSBuildAid
{
    public abstract class ModeContent : MonoBehaviour
    {
        abstract protected PluginMode workingMode { get; }
        abstract protected void DrawContent ();

        public void onModeChange (PluginMode mode)
        {
            MainWindow.DrawModeContent -= DrawContent;
            if (mode == workingMode) {
                Setup();
                MainWindow.DrawModeContent += DrawContent;
            }
        }

        protected virtual void Setup()
        {
        }

        protected virtual void Awake ()
        {
            Events.ModeChanged += onModeChange;
        }

        protected virtual void OnDestroy ()
        {
            Events.ModeChanged -= onModeChange;
            MainWindow.DrawModeContent -= DrawContent;
        }
    }
}

